module ContentFilters::Concerns::StatusConcern
  extend ActiveSupport::Concern

  included do
    scope :domain_filter_by_server_setting_scope, ->(account) {
      where.not(account_id: account.excluded_domain_by_server_setting_federation)
    }

    after_create_commit :filter_banned_keywords

    def filter_banned_keywords
      BanStatusWorker.perform_async(id)
    end

  end

  def search_word_ban(keyword)
    regex = /(?:^|\s)#{Regexp.escape(keyword)}(?:\s|[#,.]|(?=\z))/i
    !!(text =~ regex)
  end

  def search_word_in_channel_status(keyword)
    sanitized_text = text.gsub(/<br\s*\/?>/, ' ')
    sanitized_text = ActionView::Base.full_sanitizer.sanitize(sanitized_text)
    Rails.logger.info "*****Check_STATUS_TEXT #{sanitized_text}*****"
    regex = /(?:^|\s)#{Regexp.escape(keyword)}(?:\s|[#,.]|(?=\z))/i
    !!(sanitized_text =~ regex)
  end

end
