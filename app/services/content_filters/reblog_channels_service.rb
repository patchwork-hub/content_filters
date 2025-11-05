# frozen_string_literal: true
module ContentFilters
  class ReblogChannelsService < BaseService
    NON_REBOLOG_DOMAINS = %w[qlub.social qlub.channel.org thebristolcable.social].freeze

    def call(status)
      @status = status
      unless @status.sensitive? || @status.unlisted_visibility?
        community_admin_account_ids = ContentFilters::CommunityAdmin.where(is_boost_bot: true, account_status: ContentFilters::CommunityAdmin::account_statuses[:active]).pluck(:account_id)

        # Custom Channel
        process_custom_channels(community_admin_account_ids)

        # Group Channel
        process_group_channels(community_admin_account_ids)
      end
    end

    private

    def process_custom_channels(community_admin_account_ids)
      status_follower_admin_account_ids = @status.account.followers.local.channel_admins(community_admin_account_ids).pluck(:id)

      tag_ids = @status.tags.ids
      tag_follower_admin_account_ids = TagFollow.where(tag_id: tag_ids).pluck(:account_id)

      unique_admin_account_ids = (status_follower_admin_account_ids + tag_follower_admin_account_ids).uniq

      admin_accounts = []

      Account.where(id: unique_admin_account_ids).find_each do |admin_account|
        admin_account_id = admin_account&.id
        next unless admin_account_id

        community = get_community(admin_account_id)
        next unless community

        content_type = community.content_type
        next unless content_type&.custom_channel?

        # Skip if the admin_account has muted the status account
        next if Mute.exists?(account_id: admin_account_id, target_account_id: @status.account.id)

        # Skip if the admin_account does not follow the status owner and the owner is a bot
        next if !status_follower_admin_account_ids.include?(admin_account_id) && @status.account.bot?

        # Skip if `and_condition?` is true and admin_account is not in both follower lists
        if content_type&.and_condition? && !(tag_follower_admin_account_ids.include?(admin_account_id) &&
                      status_follower_admin_account_ids.include?(admin_account_id))
          next
        end

        next if newsmast_global_filter?(@status.id, community.id, 'filter_out')

        next unless valid_post_type?(community) && status_has_keyword?(@status.id, community.id, 'filter_in') && !status_has_keyword?(@status.id, community.id, 'filter_out')

        admin_accounts << admin_account_id

        unless no_boost_channel?
          ReblogChannelsWorker.perform_async(@status.id, admin_account_id) unless NON_REBOLOG_DOMAINS.include?(ENV['LOCAL_DOMAIN'])
        end
      end

      options = {admin_accounts: admin_accounts}
      DistributionWorker.perform_async(@status.id, options)
    end

    def no_boost_channel?
      ServerSetting.find_by(name: "No-Boost")&.value == true
    end

    def process_group_channels(community_admin_account_ids)
      return if @status.reply? || @status.reblog?

      community_admins = Account.where(id: community_admin_account_ids)

      admin_accounts = []

      group_channel_admins = community_admins.select do |admin_account|
        admin_account_id = admin_account&.id
        next unless admin_account_id

        community = get_community(admin_account_id)
        community&.content_type&.group_channel?
      end

      group_channel_admins.each do |admin_account|
        admin_account_id = admin_account&.id
        if @status.mentioned_account?(admin_account_id) && @status.account.follow_account?(admin_account_id)
          admin_accounts << admin_account_id
          ReblogChannelsWorker.perform_async(@status.id, admin_account_id) unless NON_REBOLOG_DOMAINS.include?(ENV['LOCAL_DOMAIN'])
        end
      end
      options = {admin_accounts: admin_accounts}
      DistributionWorker.perform_async(@status.id, options)
    end

    def valid_post_type?(community)
      community_post_type = fetch_community_post_type(community)

      return false unless community_post_type

      return false if all_post_types_excluded?(community_post_type)

      true if post_type_accepted?(community_post_type)
    end

    def fetch_community_post_type(community)
      community&.community_post_type
    end

    def all_post_types_excluded?(community_post_type)
      !any_post_types_included?(community_post_type)
    end

    def any_post_types_included?(community_post_type)
      community_post_type.posts? || community_post_type.reposts? || community_post_type.replies?
    end

    def post_type_accepted?(community_post_type)
      if @status.reply?
        community_post_type.replies?
      elsif @status.reblog?
        community_post_type.reposts?
      else
        community_post_type.posts?
      end
    end

    def get_community(account_id)
      community_id = ContentFilters::CommunityAdmin.find_by(account_id: account_id, account_status: ContentFilters::CommunityAdmin.account_statuses["active"])&.patchwork_community_id
      ContentFilters::Community.find_by(id: community_id, deleted_at: nil)
    end

    def status_has_keyword?(status_id, community_id, filter_type)
      ContentFilters::BanStatusService.new.keyword_matches_in_status?(status_id, community_id, filter_type)
    end

    def newsmast_global_filter?(status_id, community_id, filter_type = 'filter_out')
      ContentFilters::BanStatusService.new.global_keyword_matches_in_status?(status_id, community_id, filter_type)
    end
  end
end
