# frozen_string_literal: true

namespace :content_filters do
  desc 'Check tags against keyword filters and update banned status'
  task update_banned_tags: :environment do
    BanTagWorker.perform_async
  end
end
