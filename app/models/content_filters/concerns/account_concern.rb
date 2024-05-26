module ContentFilters::Concerns::AccountConcern
  extend ActiveSupport::Concern
  
  def excluded_domain_by_server_setting_federation
    user = User.find_by(account_id: id)
    Rails.cache.fetch("filter_account_ids_by_server_setting_federation:#{id}") { Account.where(domain: user.get_server_setting_exclude_domains).pluck(:id) }
  end
end
