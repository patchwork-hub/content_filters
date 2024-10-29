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

    def server_setting_federation?
      ContentFilters::ServerSetting.where(name: 'Threads', value: true).exists? || ContentFilters::ServerSetting.where(name: 'Bluesky', value: true).exists? if @account
    end

    def federation_filter_by_server_setting
      Status.domain_filter_by_server_setting_scope(@account) if @account
    end
  end
end
