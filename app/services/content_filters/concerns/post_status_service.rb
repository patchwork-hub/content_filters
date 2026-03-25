# frozen_string_literal: true

module ContentFilters::Concerns::PostStatusService
  def postprocess_status!
    super

    BanStatusWorker.perform_async(@status.id, from: 'post_status_service') if @status&.id.present?
  end
end
