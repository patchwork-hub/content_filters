# frozen_string_literal: true

class AddFetchedRepliesAtToStatuses < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:statuses, :fetched_replies_at)
      add_column :statuses, :fetched_replies_at, :datetime, null: true
    end
  end
end
