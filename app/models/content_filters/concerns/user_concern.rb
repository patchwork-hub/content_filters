# app/models/concerns/user_concern.rb
module ContentFilters::Concerns::UserConcern
    extend ActiveSupport::Concern

    DOMAIN_FILTERS = {
      'Threads': ["threads.social", "threads.net"].freeze,
      'Bluesky': ["bridgy.fed", "bluesky.social"].freeze
    }.freeze

    def get_server_setting_exclude_domains
      filter_domains = []

      DOMAIN_FILTERS.each do |setting, domains|
        federation = ContentFilters::ServerSetting.where(name: setting.to_s).first
        if federation && federation.value?
          filter_domains.concat(domains)
        end
      end

      filter_domains
    end
end
