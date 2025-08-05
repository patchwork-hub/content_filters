# frozen_string_literal: true

# frozen_string_literal: true

module ContentFilters::Concerns::TagSearchService
  extend ActiveSupport::Concern

  def from_elasticsearch
    definition = TagsIndex.query(elastic_search_query).filter(term: { is_banned: false })
    definition = definition.filter(elastic_search_filter) if @options[:exclude_unreviewed]

    ensure_exact_match(definition.limit(@limit).offset(@offset).objects.compact)
  rescue Faraday::ConnectionFailed, Parslet::ParseFailed
    nil
  end

end