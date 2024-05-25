module ContentFilters
    module TimelineFilter
        extend ActiveSupport::Concern      
          def get(limit, max_id = nil, since_id = nil, min_id = nil)
            limit    = limit.to_i
            max_id   = max_id.to_i if max_id.present?
            since_id = since_id.to_i if since_id.present?
            min_id   = min_id.to_i if min_id.present?
        
            from_redis(limit, max_id, since_id, min_id)
          end
    end
end