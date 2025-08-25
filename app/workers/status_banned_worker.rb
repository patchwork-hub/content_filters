# frozen_string_literal: true

class StatusBannedWorker
  include Sidekiq::Worker

  def perform()
    start_time = Time.current
    Rails.logger.info "Starting to check statuses against keyword filters at #{start_time}..."
    
    begin
      # Get all keyword filters (all types for statuses)
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

      # Normalize, remove leading '#', downcase, strip and deduplicate for iteration
      filter_keywords = combined_keywords.compact.map { |k| k.to_s.downcase.gsub('#', '').strip }.uniq
      
      banned_count = 0
      error_count = 0
      processed_count = 0

      # Use select to only load necessary columns for better performance
      # Only check statuses that are not already banned
      statuses_scope = Status.where(is_banned: [false, nil]).where('text IS NOT NULL AND text != ?', '').select(:id, :text, :is_banned, :local, :sensitive, :spoiler_text, :updated_at)
      total_statuses = statuses_scope.size
      Rails.logger.info "Checking #{total_statuses} non-banned statuses..."

      # Iterate all non-banned statuses
      statuses_scope.find_each do |status|
        processed_count += 1

        begin
          status_matched = false

          # Check status text using the search_word_in_status method from StatusConcern
          if status.text.present?
            filter_keywords.each do |keyword|
              if status.search_word_in_status(keyword)
                status_matched = true
                Rails.logger.info "Found keyword '#{keyword}' in status ID #{status.id}"
                break
              end
            end
          end

          if status_matched
            Rails.logger.info "Found status to ban: ID #{status.id}"

            begin
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

              banned_count += 1
            rescue => e
              error_count += 1
              Rails.logger.error "Error updating status ID #{status.id}: #{e.message}"
            end
          end

        rescue => e
          error_count += 1
          Rails.logger.error "Error processing status ID #{status.id}: #{e.message}"
          Rails.logger.error "Error in status banned worker for status #{status.id}: #{e.message}\n#{e.backtrace.join("\n")}"
        end

        # Periodic progress logging every 1000 processed statuses
        if (processed_count % 1000).zero?
          Rails.logger.info "Processed #{processed_count}/#{total_statuses} statuses (#{(processed_count.to_f / total_statuses * 100).round(2)}%)"
        end
      end
      
      end_time = Time.current
      duration = (end_time - start_time).round(2)

      Rails.logger.info "\n" + "="*50
      Rails.logger.info "SUMMARY:"
      Rails.logger.info "Total statuses processed: #{processed_count}"
      Rails.logger.info "Statuses banned: #{banned_count}"
      Rails.logger.info "Errors encountered: #{error_count}"
      Rails.logger.info "Duration: #{duration} seconds"
      Rails.logger.info "Average: #{(processed_count.to_f / duration).round(2)} statuses/second"
      Rails.logger.info "="*50

    rescue => e
      Rails.logger.error "Fatal error in status banned worker: #{e.message}"
      Rails.logger.error "Fatal error in status banned worker: #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end
end
