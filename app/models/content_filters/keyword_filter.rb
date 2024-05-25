module ContentFilters
  class KeywordFilter < ApplicationRecord
    self.table_name = 'keyword_filters'
    belongs_to :server_setting, class_name: "ContentFilters::ServerSetting", optional: true

    enum filter_type: { hashtag: 0, both: 1, content: 2 }

  end
end
