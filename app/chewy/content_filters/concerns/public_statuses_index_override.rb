module ContentFilters::Concerns::PublicStatusesIndexOverride
  extend ActiveSupport::Concern

  included do
    # Override the index_scope
    index_scope ::Status.unscoped
                        .kept
                        .indexable
                        .without_banned
                        .includes(:media_attachments, :preloadable_poll, :tags, preview_cards_status: :preview_card)
  end
end