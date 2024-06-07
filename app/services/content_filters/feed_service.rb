module ContentFilters
  class FeedService
    def initialize(account = nil)
      @account = account
    end

    def server_setting?
      content_filters = ContentFilters::ServerSetting.where(name: "Content filters").last
      return false unless content_filters
      content_filters.value
    end

    def keyword_filters_scope
      banned_keyword_status_ids = []
      server_setting = ContentFilters::ServerSetting.where(name: 'Content filters').last

      return [] unless server_setting&.value

      Status.order(created_at: :desc).limit(400).each do |status|

        ContentFilters::KeywordFilterGroup.includes(:keyword_filters).where(
        is_active: true, server_setting_id: server_setting&.id
        ).each do |keyword_filter_group|
          keyword_filter_group.keyword_filters.where(is_active: true).each do |keyword_filter|

            if keyword_filter.hashtag? || keyword_filter.both?
              keyword = keyword_filter.keyword.downcase
              tag_id = status.tags.where(name: keyword.gsub('#', '')).ids
              banned_keyword_status_ids << status.id if tag_id.present?
            end
            if keyword_filter.both? || keyword_filter.content?
              banned_keyword_status_ids << status.id if status.search_word_ban(keyword_filter.keyword)                  
            end
          end
        end

      end
      banned_keyword_status_ids
    end

    def server_setting_federation?
      ContentFilters::ServerSetting.where(name: 'Threads', value: true).exists? || ContentFilters::ServerSetting.where(name: 'Bluesky', value: true).exists? if @account
    end

    def federation_filter_by_server_setting
      Status.domain_filter_by_server_setting_scope(@account) if @account
    end
  end
end
