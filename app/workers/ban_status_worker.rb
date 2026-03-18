# frozen_string_literal: true

class BanStatusWorker
  include Sidekiq::Worker

  def perform(status_id)
    status = Status.includes(:account, :tags).find_by(id: status_id)
    return unless status

    Rails.logger.info "<<<<<<<< CALL BAN STATUS SERVICE >>>>>>>>>>"
    is_status_banned = ContentFilters::BanStatusService.new.check_and_ban_status(status)


    if is_status_banned
      Rails.logger.info "<<<<<<<< STATUS IS BANNED >>>>>>>>>>"

      attrs = {
        is_banned: is_status_banned,
        updated_at: Time.current
      }
      if status.local?
        Rails.logger.info "<<<<<<<< STATUS IS LOCAL >>>>>>>>>>"
        attrs.merge!(sensitive: true, spoiler_text: 'Sensitive content!!!')
      end
      status.update!(attrs)
    else
      Rails.logger.info "<<<<<<<< STATUS IS NOT BANNED >>>>>>>>>>"
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