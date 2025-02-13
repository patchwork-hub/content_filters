# frozen_string_literal: true

class BanStatusWorker
  include Sidekiq::Worker

  def perform(status_id)
    status = Status.find_by(id: status_id)

    # is_status_banned = ContentFilters::BanStatusService.new.check_and_ban_status(status_id)
    
    # Channel admin reblog related sub-channles service
    ReblogChannelsService.new.call(status) if ENV.fetch('MAIN_CHANNEL', nil) != 'false' && ENV.fetch('MAIN_CHANNEL', nil) != nil # && !is_status_banned

  end
end