# frozen_string_literal: true
module ContentFilters
  class ReblogChannelsService < BaseService

    def call(status)
      @status = status
      unless @status.sensitive? || @status.unlisted_visibility?
        # Channel reboost filtered by 7-day posts
        if @status.created_at < 7.days.ago.utc
          Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} skipped=older_than_7_days"
          return
        end

        community_admin_account_ids = ContentFilters::CommunityAdmin.where(is_boost_bot: true, account_status: ContentFilters::CommunityAdmin::account_statuses[:active]).pluck(:account_id)

        # Custom Channel
        Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} status=process_custom_channels_started"
        process_custom_channels(community_admin_account_ids)

        # Group Channel
        Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} status=process_group_channels_started"
        process_group_channels(community_admin_account_ids)
      else
        Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} skipped=sensitive_or_unlisted"
      end
    end

    private

    def process_custom_channels(community_admin_account_ids)

      Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} channel=custom started=(process_custom_channels)"
      # Find community admins who follow at least one account that reblogged this status.
      reblog_follower_admin_accounts = Account.where(id: community_admin_account_ids).where(
        id: Follow.where(
          target_account_id: Status.where(reblog_of_id: @status.id).select(:account_id)
        ).select(:account_id)
      ).distinct

      status_follower_admin_account_ids = @status.account.followers.local.channel_admins(community_admin_account_ids).pluck(:id)

      tag_ids = @status.tags.ids
      tag_follower_admin_account_ids = TagFollow.where(tag_id: tag_ids).pluck(:account_id)

      unique_admin_account_ids = (status_follower_admin_account_ids + tag_follower_admin_account_ids + reblog_follower_admin_accounts.pluck(:id)).uniq

      admin_accounts = []
      queued_reblogs = 0

      Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} channel=custom unique_admin_account_ids=#{unique_admin_account_ids.join(',')}"
      Account.where(id: unique_admin_account_ids).find_each do |admin_account|
        admin_account_id = admin_account&.id
        next log_admin_decision(admin_account, 'custom', 'skipped=missing_admin_id') unless admin_account_id

        community = get_community(admin_account_id)
        next log_admin_decision(admin_account, 'custom', 'skipped=community_not_found') unless community

        content_type = community.content_type
        next log_admin_decision(admin_account, 'custom', 'skipped=not_custom_channel') unless content_type&.custom_channel?

        # Skip if the admin_account has muted the status account
        next log_admin_decision(admin_account, 'custom', 'skipped=author_muted') if Mute.exists?(account_id: admin_account_id, target_account_id: @status.account.id)

        # Skip if the admin_account does not follow the status owner and the owner is a bot
        next log_admin_decision(admin_account, 'custom', 'skipped=bot_author_not_followed') if !status_follower_admin_account_ids.include?(admin_account_id) && @status.account.bot?

        # Skip if `and_condition?` is true and admin_account is not in both follower lists
        if content_type&.and_condition? && !(tag_follower_admin_account_ids.include?(admin_account_id) &&
                      status_follower_admin_account_ids.include?(admin_account_id))
          log_admin_decision(admin_account, 'custom', 'skipped=author_and_tag_follow_required')
          next
        end

        next log_admin_decision(admin_account, 'custom', 'skipped=global_filter_out') if newsmast_global_filter?(@status.id, community.id, 'filter_out')

        next log_admin_decision(admin_account, 'custom', 'skipped=post_type_not_allowed') unless valid_post_type?(community)
        next log_admin_decision(admin_account, 'custom', 'skipped=filter_in_not_matched') unless status_has_keyword?(@status.id, community.id, 'filter_in')
        next log_admin_decision(admin_account, 'custom', 'skipped=filter_out_matched') if status_has_keyword?(@status.id, community.id, 'filter_out')

        admin_accounts << admin_account_id

        # skip if no_boost_channel is true
        unless community&.no_boost_channel
          jid = ReblogChannelsWorker.perform_async(@status.id, admin_account_id)
          Rails.logger.info(
            event: 'channel_reblog_enqueued(custom)',
            path: 'custom',
            status_id: @status.id,
            status_uri: @status.uri,
            admin_account_id: admin_account_id,
            admin_username: admin_account&.username.to_s.dump,
            jid: jid
          )
          queued_reblogs += 1
          log_admin_decision(admin_account, 'custom', 'reblog_queued=true')
        else
          log_admin_decision(admin_account, 'custom', 'skipped=boost_disabled')
        end
      end

      # check channel's self-post
      community = get_community(@status.account_id)
      admin_accounts << @status.account_id if community

      options = {"admin_accounts" => admin_accounts}
      DistributionWorker.perform_async(@status.id, options)
      Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} channel=custom matched=#{admin_accounts.size} matched_accounts=#{admin_accounts.map(&:to_s).join(',')} reblogs_queued=#{queued_reblogs} distribution_queued=true"
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
          Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} channel=group admin_id=#{admin_account_id} admin_username=#{admin_account&.username.to_s.dump} reblog_queued=true"
          jid = ReblogChannelsWorker.perform_async(@status.id, admin_account_id)
          Rails.logger.info(
            event: 'channel_reblog_enqueued(group)',
            path: 'group',
            status_id: @status.id,
            status_uri: @status.uri,
            admin_account_id: admin_account_id,
            admin_username: admin_account&.username.to_s.dump,
            jid: jid
          )
        end
      end
      options = {"admin_accounts" => admin_accounts}
      DistributionWorker.perform_async(@status.id, options)
    end

    def log_admin_decision(admin_account, channel, decision)
      Rails.logger.info "[ReblogChannelsService] status_id=#{@status.id} channel=#{channel} admin_id=#{admin_account&.id} admin_username=#{admin_account&.username.to_s.dump} #{decision}"
      nil
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
