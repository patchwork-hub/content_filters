# frozen_string_literal: true

class BanStatusWorker
  include Sidekiq::Worker

  def perform(status_id)
    ContentFilters::BanStatusService.new.check_and_ban_status(status_id)
  end
end