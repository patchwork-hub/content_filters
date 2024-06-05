
module ContentFilters
  class KeywordFilterGroup < ApplicationRecord
  self.table_name = 'keyword_filter_groups'

  belongs_to :server_setting, class_name: "ContentFilters::ServerSetting", optional: true
  has_many :keyword_filters, class_name: "ContentFilters::KeywordFilter", dependent: :destroy

  validates :name, presence: true

  end
end
