module ContentFilters::Concerns::PublicStatusesIndexOverride
  extend ActiveSupport::Concern

  included do
    # Override the index_scope
    index_scope ::Status.unscoped
                        .kept
                        .indexable
                        .where(is_banned: false) # Add your custom condition
                        .includes(:media_attachments, :preloadable_poll, :tags, preview_cards_status: :preview_card)
  end
end