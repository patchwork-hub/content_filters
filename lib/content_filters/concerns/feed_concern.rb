module ContentFilters
    module FeedConcern
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

        # def server_setting?
        #   content_filters = ServerSetting.where(name: "Content filters").last
        #   return false unless content_filters
        #   content_filters.value
        # end
      
        # def keyword_filters_scope
        #   banned_keyword_status_ids = []
      
        #   Status.order(created_at: :desc).limit(400).each do |status|
        #     KeywordFilter.all.each do |keyword_filter|
      
        #       if keyword_filter.is_filter_hashtag
        #         keyword = keyword_filter.keyword.downcase
        #         tag_id = status.tags.where(name: keyword.gsub('#', '')).ids
        #         banned_keyword_status_ids << status.id if tag_id.present?
        #       else
        #         banned_keyword_status_ids << status.id if status.search_word_ban(keyword_filter.keyword)
        #       end
      
        #     end
        #   end
        # end
    end
end