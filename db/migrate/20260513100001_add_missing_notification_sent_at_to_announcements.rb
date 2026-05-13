# frozen_string_literal: true

class AddMissingNotificationSentAtToAnnouncements < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:announcements, :notification_sent_at)
      add_column :announcements, :notification_sent_at, :datetime
    end
  end
end
