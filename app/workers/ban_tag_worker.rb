# frozen_string_literal: true

class BanTagWorker
  include Sidekiq::Worker

  def perform()
    start_time = Time.current
    puts "Starting to check tags against keyword filters at #{start_time}..."
    
    begin
      # Get all keyword filters of type hashtag or both
      keyword_filters = ContentFilters::KeywordFilter.where(filter_type: [:hashtag, :both])
      # Community filters scoped to global (patchwork_community_id: nil) and filter_out
      community_keyword_filters = ContentFilters::CommunityFilterKeyword.where(patchwork_community_id: nil, is_filter_hashtag: true, filter_type: 'filter_out')

      if keyword_filters.empty? && community_keyword_filters.empty?
        puts "No hashtag or both type keyword filters found. Exiting."
        return
      end

      # Report counts for visibility
      puts "Found #{keyword_filters.count} keyword filters and #{community_keyword_filters.count} community keyword filters to check against"

      # Combine keywords from both sources and remove duplicates
      combined_keywords = keyword_filters.pluck(:keyword) + community_keyword_filters.pluck(:keyword)

      # Normalize, remove leading '#', downcase, strip and deduplicate using Set for O(1) lookup
      filter_keywords = Set.new(combined_keywords.compact.map { |k| k.to_s.downcase.gsub('#', '').strip })
      
      banned_count = 0
      error_count = 0
      processed_count = 0
      batch_size = 1000
      
      # Use select to only load necessary columns for better performance
      total_tags = Tag.count
      puts "Checking #{total_tags} tags in batches of #{batch_size}..."
      
      # Process tags in batches with transaction for better performance
      Tag.select(:id, :name, :display_name, :listable, :trendable).find_in_batches(batch_size: batch_size) do |tag_batch|
        # Collect all tag IDs that need to be banned in this batch
        tags_to_ban = []
        
        tag_batch.each do |tag|
          processed_count += 1
          
          begin
            next unless tag.listable && tag.trendable # Skip already banned tags
            
            tag_matched = false
            
            # Performance optimized: Check exact match first, then substring
            tag_name_lower = tag.name.downcase.strip
            if filter_keywords.include?(tag_name_lower)
              tag_matched = true
            elsif filter_keywords.any? { |keyword| tag_name_lower.include?(keyword) }
              tag_matched = true
            end
            
            # Check display_name if exists and not already matched
            if !tag_matched && tag.respond_to?(:display_name) && tag.display_name.present?
              display_name_lower = tag.display_name.downcase.strip
              if filter_keywords.include?(display_name_lower)
                tag_matched = true
              elsif filter_keywords.any? { |keyword| display_name_lower.include?(keyword) }
                tag_matched = true
              end
            end
            
            if tag_matched
              tags_to_ban << tag.id
              puts "Found tag to ban: '#{tag.name}' (ID: #{tag.id})"
            end
            
          rescue => e
            error_count += 1
            puts "Error processing tag ID #{tag.id}: #{e.message}"
            Rails.logger.error "Error in update_banned_tags for tag #{tag.id}: #{e.message}\n#{e.backtrace.join("\n")}"
          end
        end
        
        # Batch update for better performance
        if tags_to_ban.any?
          begin
            Tag.where(id: tags_to_ban).find_each do |tag|
              tag.update!(listable: false, trendable: false)

              tag.statuses.each do |status|
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
          end
            puts "Batch updated #{tags_to_ban.size} tags to banned status"
          rescue => e
            puts "Error in batch update: #{e.message}"
            Rails.logger.error "Batch update error in update_banned_tags: #{e.message}\n#{e.backtrace.join("\n")}"
            
            # Fallback to individual updates
            tags_to_ban.each do |tag_id|
              begin
                tag = Tag.find(tag_id)
                tag.update!(listable: false, trendable: false)
                banned_count += 1
              rescue => e
                error_count += 1
                puts "Error updating tag ID #{tag_id}: #{e.message}"
                Rails.logger.error "Individual update error for tag #{tag_id}: #{e.message}"
              end
            end
          end
        end
        
        # Progress update
        puts "Processed #{processed_count}/#{total_tags} tags (#{(processed_count.to_f / total_tags * 100).round(2)}%)"
      end
      
      end_time = Time.current
      duration = (end_time - start_time).round(2)
      
      puts "\n" + "="*50
      puts "SUMMARY:"
      puts "Total tags processed: #{processed_count}"
      puts "Tags updated to banned: #{banned_count}"
      puts "Errors encountered: #{error_count}"
      puts "Duration: #{duration} seconds"
      puts "Average: #{(processed_count.to_f / duration).round(2)} tags/second"
      puts "="*50
      
    rescue => e
      puts "Fatal error in update_banned_tags: #{e.message}"
      Rails.logger.error "Fatal error in update_banned_tags: #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end
end
