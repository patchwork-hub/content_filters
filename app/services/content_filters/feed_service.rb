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

      setting_filter_types = ['Content filters', 'Spam filters']

      setting_filter_types.each do |setting_filter_type|

        # Cache the server setting lookup for 30 minutes
        server_setting = Rails.cache.fetch("server_setting_#{setting_filter_type}", expires_in: 30.minutes) do
          ContentFilters::ServerSetting.find_by(name: setting_filter_type)
        end
        
        next unless server_setting&.value

        # Cache keyword filter groups lookup for 10 seconds
        keyword_filter_groups = Rails.cache.fetch("keyword_filter_groups_#{server_setting.id}", expires_in: 10.minutes) do
          ContentFilters::KeywordFilterGroup.includes(:keyword_filters)
                                          .where(is_active: true, server_setting_id: server_setting.id)
        end

        # Cache the status lookup for 10 seconds
        statuses = Rails.cache.fetch("recent_statuses", expires_in: 5.minutes) do
          Status.order(created_at: :desc).limit(50).includes(:tags)
        end

        keyword_filter_groups.each do |keyword_filter_group|
          keyword_filter_group.keyword_filters.each do |keyword_filter|
            keyword = keyword_filter.keyword.downcase

            statuses.each do |status|
              if keyword_filter.hashtag? || keyword_filter.both?
                tag_id = status.tags.where(name: keyword.gsub('#', '')).ids
                banned_keyword_status_ids << status.id if tag_id.present?
              end
              if keyword_filter.both? || keyword_filter.content?
                banned_keyword_status_ids << status.id if status.search_word_ban(keyword_filter.keyword)
              end
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
