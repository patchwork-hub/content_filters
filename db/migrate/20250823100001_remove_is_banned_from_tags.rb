# frozen_string_literal: true

class RemoveIsBannedFromTags < ActiveRecord::Migration[7.0]
  def change
    if column_exists?(:tags, :is_banned)
      safety_assured { remove_column :tags, :is_banned, :boolean }
    end
  end
end
