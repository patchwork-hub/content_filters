module ContentFilters::Concerns::StatusConcern
  extend ActiveSupport::Concern

  included do
    scope :domain_filter_by_server_setting_scope, ->(account) {
      where.not(account_id: account.excluded_domain_by_server_setting_federation)
    }

    scope :without_banned, -> { where(statuses: { is_banned: false }) }

    # Override the scope of Status::SearchConcern
    scope :indexable, -> { without_reblogs.without_banned.public_visibility.joins(:account).where(account: { indexable: true }) }

    after_create_commit :filter_banned_keywords

    def filter_banned_keywords
      BanStatusWorker.perform_async(id)
    end
  end

  def search_word_in_status(keyword)
    sanitized_text = text.gsub(/<br\s*\/?>/, ' ').gsub(/<\/?p>/, ' ')
    sanitized_text = ActionView::Base.full_sanitizer.sanitize(sanitized_text)
    regex = /(?:^|\s)#{Regexp.escape(keyword)}(?:\s|[#,.]|(?=\z))/i
    !!(sanitized_text =~ regex)
  end

end
