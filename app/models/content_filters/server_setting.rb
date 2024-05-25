module ContentFilters
  class ServerSetting < ApplicationRecord
    validates :name, presence: true

    has_many :user_server_settings
    has_many :users, through: :user_server_settings

    belongs_to :parent, class_name: "ContentFilters::ServerSetting", optional: true
    has_many :children, class_name: "ContentFilters::ServerSetting", foreign_key: "parent_id"
  end
end
