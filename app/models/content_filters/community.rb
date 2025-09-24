# frozen_string_literal: true
module ContentFilters
  class Community < ApplicationRecord
    self.table_name = 'patchwork_communities'

    LIMIT = 2.megabytes

    has_many :community_admins,
    foreign_key: 'patchwork_community_id',
    dependent: :destroy,
    class_name: 'ContentFilters::CommunityAdmin'

    has_one :community_post_type,
    foreign_key: 'patchwork_community_id',
    dependent: :destroy,
    class_name: 'ContentFilters::CommunityPostType'

    has_many :community_hashtags,
    class_name: 'ContentFilters::CommunityHashtag',
    foreign_key: 'patchwork_community_id',
    dependent: :destroy

    has_one :content_type,
    class_name: 'ContentFilters::ContentType',
    foreign_key: 'patchwork_community_id',
    dependent: :destroy

    validates :name, presence: true, uniqueness: true

    enum :visibility, public_access: 0, guest_access: 1, private_local: 2

    enum :post_visibility, { public_visibility: 0, unlisted: 1, followers_only: 2, direct: 3 }

  end
end
