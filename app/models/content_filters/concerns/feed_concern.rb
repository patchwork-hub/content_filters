module ContentFilters::Concerns::FeedConcern
    extend ActiveSupport::Concern  

    def from_redis(limit, max_id, since_id, min_id)
      max_id = '+inf' if max_id.blank?
      if min_id.blank?
        since_id   = '-inf' if since_id.blank?
        unhydrated = redis.zrevrangebyscore(key, "(#{max_id}", "(#{since_id}", limit: [0, limit], with_scores: true).map { |id| id.first.to_i }
      else
        unhydrated = redis.zrangebyscore(key, "(#{min_id}", "(#{max_id}", limit: [0, limit], with_scores: true).map { |id| id.first.to_i }
      end
  
      #Status.where(id: unhydrated)
      filter_and_cache_statuses(unhydrated)
    end

    def filter_and_cache_statuses(unhydrated)
      filter_service = ContentFilters::FeedService.new()
      banned_ids = []
      if filter_service.server_setting?
        banned_ids = filter_service.keyword_filters_scope
      end
      statuses = Status.where(id: unhydrated)
      statuses = statuses.where.not(id: banned_ids) if banned_ids.any?
      statuses
    end
      
end