# frozen_string_literal: true

class BanStatusWorker
  include Sidekiq::Worker

  def perform(status_id)
    status = Status.find_by(id: status_id)
    return unless status

    is_status_banned = ContentFilters::BanStatusService.new.check_and_ban_status(status)

    if is_status_banned

      status.update!(
        is_banned: is_status_banned,
        updated_at: Time.current
      )

      if status.local?
        status.update!(
          sensitive: true,
          spoiler_text: 'Sensitive content!!!'
        )
      end

      # # Call `update_index` after the status is updated
      # status.update_index('statuses', :proper)
      # status.update_index('public_statuses', :proper)
    else
      # Channel admin reblog related sub-channles service
      if ENV.fetch('MAIN_CHANNEL', nil) != 'false' && ENV.fetch('MAIN_CHANNEL', nil) != nil && !is_status_banned
        ReblogChannelsService.new.call(status) 
      end
    end
  end
end