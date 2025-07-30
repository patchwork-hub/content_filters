module ContentFilters::Concerns::StatusesIndexOverride
  extend ActiveSupport::Concern

  included do
    # Override the index_scope
    index_scope ::Status.unscoped.kept.without_reblogs.where(is_banned: false).includes(:media_attachments, :local_mentioned, :local_favorited, :local_reblogged, :local_bookmarked, :tags, preview_cards_status: :preview_card, preloadable_poll: :local_voters), delete_if: ->(status) { status.searchable_by.empty? }

  end
end