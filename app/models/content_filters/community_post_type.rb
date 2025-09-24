# frozen_string_literal: true
module ContentFilters
  class CommunityPostType < ApplicationRecord
    self.table_name = 'patchwork_community_post_types'

    belongs_to :community,
              class_name: 'ContentFilters::Community',
              foreign_key: 'patchwork_community_id'
  end
end
