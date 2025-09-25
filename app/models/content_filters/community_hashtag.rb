# frozen_string_literal: true
module ContentFilters
  class CommunityHashtag < ApplicationRecord
    self.table_name = 'patchwork_communities_hashtags'

    belongs_to :community,
              class_name: 'ContentFilters::Community',
              foreign_key: 'patchwork_community_id'
  end
end
