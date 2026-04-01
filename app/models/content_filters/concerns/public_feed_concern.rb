module ContentFilters::Concerns::PublicFeedConcern
  extend ActiveSupport::Concern
  include Redisable

 # @param [Account] account
  # @param [Hash] options
  # @option [Boolean] :with_replies
  # @option [Boolean] :with_reblogs
  # @option [Boolean] :local
  # @option [Boolean] :remote
  # @option [Boolean] :only_media
  # @option [Boolean] :grouped_admin_statuses
  def initialize(account, options = {})
    @account = account
    @options = options
  end

  # @param [Integer] limit
  # @param [Integer] max_id
  # @param [Integer] since_id
  # @param [Integer] min_id
  # @return [Array<Status>]
  def get(limit, max_id = nil, since_id = nil, min_id = nil)
    scope = public_scope

    scope.merge!(without_replies_scope) unless with_replies?
    scope.merge!(without_reblogs_scope) unless with_reblogs? || ENV['LOCAL_DOMAIN'] == 'thebristolcable.social'
    scope.merge!(local_only_scope) if local_only?
    scope.merge!(remote_only_scope) if remote_only?
    scope.merge!(account_filters_scope) if account?
    scope.merge!(media_only_scope) if media_only?
    scope.merge!(grouped_admin_statuses_scope) if grouped_admin_statuses?
    scope.merge!(language_scope) if account&.chosen_languages.present?
    scope = apply_filters(scope)
    scope.to_a_paginated_by_id(limit, max_id: max_id, since_id: since_id, min_id: min_id)
  end

  private

  attr_reader :account, :options

  def with_reblogs?
    options[:with_reblogs]
  end

  def with_replies?
    options[:with_replies]
  end

  def local_only?
    options[:local] && !options[:remote]
  end

  def remote_only?
    options[:remote] && !options[:local]
  end

  def account?
    account.present?
  end

  def media_only?
    options[:only_media]
  end

  def public_scope
    Status.public_visibility.joins(:account).merge(Account.without_suspended.without_silenced)
  end

  def local_only_scope
    Status.local
  end

  def remote_only_scope
    Status.remote
  end

  def without_replies_scope
    Status.without_replies
  end

  def without_reblogs_scope
    Status.without_reblogs
  end

  def media_only_scope
    Status.joins(:media_attachments).group(:id)
  end

  def language_scope
    Status.where(language: account.chosen_languages)
  end

  def account_filters_scope
    Status.not_excluded_by_account(account).tap do |scope|
      scope.merge!(Status.not_domain_blocked_by_account(account)) unless local_only?
    end
  end

  def apply_filters(scope)
    service = ContentFilters::FeedService.new(@account)

    banned_ids = service.excluded_status_ids
    scope = scope.where.not(id: banned_ids) if banned_ids.any?

    scope.merge!(service.federation_filter_by_server_setting) if service.server_setting_federation?
    scope
  end

  def grouped_admin_statuses?
    options[:grouped_admin_statuses]
  end

  def grouped_admin_statuses_scope
    grouped_admin_account_ids = fetch_grouped_admin_account_ids
    Status.where.not(account_id: grouped_admin_account_ids)
  end

  def fetch_grouped_admin_account_ids
    Rails.cache.fetch("grouped_admin_account_ids", expires_in: 1.hour) do
      ContentFilters::CommunityAdmin
        .includes(:community)
        .where(
          is_boost_bot: true,
          account_status: ContentFilters::CommunityAdmin.account_statuses[:active],
          community: { channel_type: ContentFilters::Community.channel_types[:channel_feed] }
        )
        .pluck(:account_id)
        .uniq
    end
  end
end
