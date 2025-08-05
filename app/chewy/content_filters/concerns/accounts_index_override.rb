module ContentFilters::Concerns::AccountsIndexOverride
  extend ActiveSupport::Concern

  included do
    index_scope ::Account.searchable.without_banned.includes(:account_stat)
  end
end
