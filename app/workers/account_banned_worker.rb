# frozen_string_literal: true

class AccountBannedWorker
  include Sidekiq::Worker

  def perform()
    start_time = Time.current
    Rails.logger.info "Starting to check accounts against keyword filters at #{start_time}..."
    
    begin
      # Get all keyword filters (all types for accounts)
      keyword_filters = ContentFilters::KeywordFilter.all
      # Community filters scoped to global (patchwork_community_id: nil) and filter_out
      community_keyword_filters = ContentFilters::CommunityFilterKeyword.where(patchwork_community_id: nil, filter_type: 'filter_out')

      if keyword_filters.empty? && community_keyword_filters.empty?
        Rails.logger.info "No keyword filters found. Exiting."
        return
      end

      # Report counts for visibility
      Rails.logger.info "Found #{keyword_filters.count} keyword filters and #{community_keyword_filters.count} community keyword filters to check against"

      # Combine keywords from both sources and remove duplicates
      combined_keywords = keyword_filters.pluck(:keyword) + community_keyword_filters.pluck(:keyword)

      # Normalize, remove leading '#', downcase, strip and deduplicate using Set for O(1) lookup
      filter_keywords = Set.new(combined_keywords.compact.map { |k| k.to_s.downcase.gsub('#', '').strip })
      
      banned_count = 0
      error_count = 0
      processed_count = 0

      # Use select to only load necessary columns for better performance
      # Only check accounts that are not already banned
      accounts_scope = Account.where(is_banned: [false, nil]).select(:id, :username, :display_name, :note, :is_banned)
      total_accounts = accounts_scope.count
      Rails.logger.info "Checking #{total_accounts} non-banned accounts..."

      # Iterate all non-banned accounts
      accounts_scope.find_each do |account|
        processed_count += 1

        begin
          account_matched = false

          # Check username
          if account.username.present?
            username_lower = account.username.downcase.strip
            if filter_keywords.include?(username_lower)
              account_matched = true
            elsif filter_keywords.any? { |keyword| username_lower.include?(keyword) }
              account_matched = true
            end
          end

          # Check display_name if not already matched
          if !account_matched && account.display_name.present?
            display_name_lower = account.display_name.downcase.strip
            if filter_keywords.include?(display_name_lower)
              account_matched = true
            elsif filter_keywords.any? { |keyword| display_name_lower.include?(keyword) }
              account_matched = true
            end
          end

          # Check note if not already matched
          if !account_matched && account.note.present?
            note_lower = account.note.downcase.strip
            if filter_keywords.include?(note_lower)
              account_matched = true
            elsif filter_keywords.any? { |keyword| note_lower.include?(keyword) }
              account_matched = true
            end
          end

          if account_matched
            Rails.logger.info "Found account to ban: '#{account.username}' (ID: #{account.id}, Display: '#{account.display_name}')"

            begin
              account.update!(is_banned: true)

              account.statuses.each do |status|
                status.update!(
                  is_banned: true,
                  updated_at: Time.current
                )

                if status.local?
                  status.update!(
                    sensitive: true,
                    spoiler_text: 'Sensitive content!!!'
                  )
                end
              end

              banned_count += 1
            rescue => e
              error_count += 1
              Rails.logger.error "Error updating account ID #{account.id}: #{e.message}"
            end
          end

        rescue => e
          error_count += 1
          Rails.logger.error "Error processing account ID #{account.id}: #{e.message}"
          Rails.logger.error "Error in account banned worker for account #{account.id}: #{e.message}\n#{e.backtrace.join("\n")}"
        end

        # Periodic progress logging every 1000 processed accounts
        if (processed_count % 1000).zero?
          Rails.logger.info "Processed #{processed_count}/#{total_accounts} accounts (#{(processed_count.to_f / total_accounts * 100).round(2)}%)"
        end
      end
      
      end_time = Time.current
      duration = (end_time - start_time).round(2)

      Rails.logger.info "\n" + "="*50
      Rails.logger.info "SUMMARY:"
      Rails.logger.info "Total accounts processed: #{processed_count}"
      Rails.logger.info "Accounts banned: #{banned_count}"
      Rails.logger.info "Errors encountered: #{error_count}"
      Rails.logger.info "Duration: #{duration} seconds"
      Rails.logger.info "Average: #{(processed_count.to_f / duration).round(2)} accounts/second"
      Rails.logger.info "="*50

    rescue => e
      Rails.logger.error "Fatal error in account banned worker: #{e.message}"
      Rails.logger.error "Fatal error in account banned worker: #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end
end
