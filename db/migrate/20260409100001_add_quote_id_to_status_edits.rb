# frozen_string_literal: true

class AddQuoteIdToStatusEdits < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:status_edits, :quote_id)
      add_column :status_edits, :quote_id, :bigint, null: true
    end
  end
end
