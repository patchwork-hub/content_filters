module ContentFilters::Concerns::FeedConcern
    extend ActiveSupport::Concern  
    include Redisable

    def get(limit, max_id = nil, since_id = nil, min_id = nil, account = nil, exclude_direct_statuses = false, exclude_followed_tags = false, exclude_replies = false)
      if account.present? && exclude_followed_tags
        @account = account
      end

      limit    = limit.to_i
      max_id   = max_id.to_i if max_id.present?
      since_id = since_id.to_i if since_id.present?
      min_id   = min_id.to_i if min_id.present?

      from_redis(limit, max_id, since_id, min_id, exclude_direct_statuses, exclude_followed_tags, exclude_replies)
    end

    def from_redis(limit, max_id, since_id, min_id, exclude_direct_statuses = nil, exclude_followed_tags = nil, exclude_replies = nil)
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

      @statuses
    end

    def filter_and_cache_statuses(unhydrated)
      filter_service = ContentFilters::FeedService.new()
      banned_ids = filter_service.excluded_status_ids
      @statuses = Status.where(id: unhydrated)
      @statuses = @statuses.where.not(id: banned_ids) if banned_ids.any?
      @statuses
    end
end
