module ContentFilters::Concerns::StatusFilterConcern
  extend ActiveSupport::Concern

  private

  def status_banned?
    status.is_banned?
  end

  # Override the filtered? method to include status_banned? check
  def filtered?
    return false if !account.nil? && account.id == status.account_id

    blocked_by_policy? || (account_present? && filtered_status?) || silenced_account? || status_banned?
  end
end
