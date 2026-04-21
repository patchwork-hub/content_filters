module ContentFilters::Concerns::FeedConcern
    extend ActiveSupport::Concern  
    include Redisable

    def get(limit, max_id = nil, since_id = nil, min_id = nil, account = nil, exclude_direct_statuses = false, exclude_followed_tags = false, exclude_replies = false, grouped_admin_statuses = false)
      if account.present? && exclude_followed_tags
        @account = account
      end

      limit    = limit.to_i
      max_id   = max_id.to_i if max_id.present?
      since_id = since_id.to_i if since_id.present?
      min_id   = min_id.to_i if min_id.present?

      from_redis(limit, max_id, since_id, min_id, exclude_direct_statuses, exclude_followed_tags, exclude_replies, grouped_admin_statuses)
    end

    def from_redis(limit, max_id, since_id, min_id, exclude_direct_statuses = nil, exclude_followed_tags = nil, exclude_replies = nil, grouped_admin_statuses = nil)
      max_id = '+inf' if max_id.blank?
      if min_id.blank?
        since_id   = '-inf' if since_id.blank?
        unhydrated = redis.zrevrangebyscore(key, "(#{max_id}", "(#{since_id}", limit: [0, limit], with_scores: true).map { |id| id.first.to_i }
      else
        unhydrated = redis.zrangebyscore(key, "(#{min_id}", "(#{max_id}", limit: [0, limit], with_scores: true).map { |id| id.first.to_i }
      end
  
      filter_and_cache_statuses(unhydrated)

      if exclude_direct_statuses
        @statuses = @statuses.where(visibility: %i(public unlisted))
      end

      if exclude_followed_tags
        followed_tag_ids = @account.followed_tags.pluck(:id)
        @statuses = @statuses.tagged_without(followed_tag_ids)
      end

      if exclude_replies
        @statuses = @statuses.where(reply: false)
      end

      if grouped_admin_statuses
        return @statuses unless Status.column_names.include?('local_only')

        grouped_admin_account_ids = fetch_grouped_admin_account_ids
        if grouped_admin_account_ids.any?
          @statuses = @statuses.where.not(account_id: grouped_admin_account_ids, local_only: true, local: true)

          # To prevent showing reblogs of grouped admin accounts, we also need to exclude any statuses that are reblogs of the grouped admin accounts' statuses. We only need to check local_only: true and local: true statuses for reblogs, as the grouped admin accounts are only posting local statuses.
          grouped_admin_reblogged_ids = Status.where(account_id: grouped_admin_account_ids, local_only: true, local: true).pluck(:reblog_of_id).compact
          @statuses = @statuses.where.not(id: grouped_admin_reblogged_ids) if grouped_admin_reblogged_ids.any?
        end
      end

      @statuses
    end

    def filter_and_cache_statuses(unhydrated)
      filter_service = ContentFilters::FeedService.new()
      banned_ids = filter_service.excluded_status_ids
      @statuses = Status.where(id: unhydrated)
      @statuses = @statuses.where.not(id: banned_ids) if banned_ids.any?
      @statuses
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
