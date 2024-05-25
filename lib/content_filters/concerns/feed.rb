module ContentFilters
    module Feed
        extend ActiveSupport::Concern      
        def from_redis(limit, max_id, since_id, min_id)
          max_id = '+inf' if max_id.blank?
          if min_id.blank?
            since_id   = '-inf' if since_id.blank?
            unhydrated = redis.zrevrangebyscore(key, "(#{max_id}", "(#{since_id}", limit: [0, limit], with_scores: true).map { |id| id.first.to_i }
          else
            unhydrated = redis.zrangebyscore(key, "(#{min_id}", "(#{max_id}", limit: [0, limit], with_scores: true).map { |id| id.first.to_i }
          end
          Status.where(id: unhydrated)
        end
    end
end