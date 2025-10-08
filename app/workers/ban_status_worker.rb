# frozen_string_literal: true

class BanStatusWorker
  include Sidekiq::Worker

  def perform(status_id)
    # Temporary skip for thebristolcable.social
    return if (ENV.fetch('LOCAL_DOMAIN', nil)) == 'thebristolcable.social'

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
    else
      ContentFilters::ReblogChannelsService.new.call(status) if reblog_enabled?(is_status_banned)
    end
  end

  private
  def reblog_enabled?(is_status_banned)
    ((ENV.fetch('MAIN_CHANNEL', nil) != 'false' && ENV.fetch('MAIN_CHANNEL', nil) != nil) ||
    (ENV.fetch('BOOST_BOT_ENABLED', nil) != 'false' && ENV.fetch('BOOST_BOT_ENABLED', nil) != nil)) &&
    !is_status_banned
  end
end