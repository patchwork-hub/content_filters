module ContentFilters::Concerns::StatusConcern
  extend ActiveSupport::Concern  

  def search_word_ban(keyword)
    regex = /(?:^|\s)#{Regexp.escape(keyword)}(?:\s|[#,.]|(?=\z))/i 
    !!(text =~ regex)
  end

end