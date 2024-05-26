module ContentFilters::Concerns::StatusConcern
  extend ActiveSupport::Concern  

  included do
    scope :domain_filter_by_server_setting_scope, ->(account) {
      where.not(account_id: account.excluded_domain_by_server_setting_federation)
    }
  end
  
  def search_word_ban(keyword)
    regex = /(?:^|\s)#{Regexp.escape(keyword)}(?:\s|[#,.]|(?=\z))/i 
    !!(text =~ regex)
  end



end