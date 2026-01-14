module ContentFilters
  class CustomBoostBotService < BaseService
    require 'httparty'

    def initialize
      @base_url = ENV.fetch('BRISTOL_CABLE_INSTANCE_URL', nil)
      @client_id = ENV.fetch('BRISTOL_CABLE_CLIENT_ID', nil)
      @client_secret = ENV.fetch('BRISTOL_CABLE_CLIENT_SECRET', nil)
    end

    def call(status_id)
      status = Status.find_by(id: status_id)
      return false unless status
      url = @base_url + "/api/v1/custom_statuses/add_custom_boost_bot_status"

      response = HTTParty.post(url,
                    body: {
                        client_id: @client_id,
                        client_secret: @client_secret,
                        status_url: status.uri 
                    }.to_json,
                    headers: { 'Content-Type' => 'application/json'})
    end
  end
end