# frozen_string_literal: true

namespace :content_filters do
  desc 'Check tags against keyword filters and update banned status'
  task update_banned_tags: :environment do
    start_time = Time.current
    puts "Starting to check tags against keyword filters at #{start_time}..."
    
    begin
      # Get all keyword filters of type hashtag or both
      keyword_filters = ContentFilters::KeywordFilter.where(filter_type: [:hashtag, :both])
      
      if keyword_filters.empty?
        puts "No hashtag or both type keyword filters found. Exiting."
        return
      end
      
      puts "Found #{keyword_filters.count} keyword filters to check against"
      
      # Create Set of keywords for O(1) lookup performance
      filter_keywords = Set.new(keyword_filters.pluck(:keyword).map do |keyword|
        # Remove # symbol if present and convert to lowercase
        keyword.downcase.gsub('#', '').strip
      end)
      
      banned_count = 0
      error_count = 0
      processed_count = 0
      batch_size = 1000
      
      # Use select to only load necessary columns for better performance
      total_tags = Tag.count
      puts "Checking #{total_tags} tags in batches of #{batch_size}..."
      
      # Process tags in batches with transaction for better performance
      Tag.select(:id, :name, :display_name, :is_banned).find_in_batches(batch_size: batch_size) do |tag_batch|
        # Collect all tag IDs that need to be banned in this batch
        tags_to_ban = []
        
        tag_batch.each do |tag|
          processed_count += 1
          
          begin
            next if tag.is_banned # Skip already banned tags
            
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
  
  desc 'Check tags against keyword filters and show matches without updating'
  task preview_banned_tags: :environment do
    start_time = Time.current
    puts "Previewing tags that would be banned..."
    
    begin
      # Get all keyword filters of type hashtag or both
      keyword_filters = ContentFilters::KeywordFilter.where(filter_type: [:hashtag, :both])
      
      if keyword_filters.empty?
        puts "No hashtag or both type keyword filters found. Exiting."
        return
      end
      
      puts "Found #{keyword_filters.count} keyword filters:"
      keyword_filters.each do |filter|
        puts "  - '#{filter.keyword}' (#{filter.filter_type})"
      end
      puts ""
      
      # Create Set of keywords for O(1) lookup performance
      filter_keywords = Set.new(keyword_filters.pluck(:keyword).map do |keyword|
        keyword.downcase.gsub('#', '').strip
      end)
      
      matches = []
      processed_count = 0
      error_count = 0
      batch_size = 1000
      
      # Process in batches for better memory management
      Tag.select(:id, :name, :display_name, :is_banned).find_in_batches(batch_size: batch_size) do |tag_batch|
        tag_batch.each do |tag|
          processed_count += 1
          
          begin
            tag_matched = false
            matched_keyword = nil
            
            # Performance optimized: Check exact match first, then substring
            tag_name_lower = tag.name.downcase.strip
            if filter_keywords.include?(tag_name_lower)
              tag_matched = true
              matched_keyword = tag_name_lower
            else
              matched_keyword = filter_keywords.find { |keyword| tag_name_lower.include?(keyword) }
              tag_matched = true if matched_keyword
            end
            
            # Check display_name if exists and not already matched
            if !tag_matched && tag.respond_to?(:display_name) && tag.display_name.present?
              display_name_lower = tag.display_name.downcase.strip
              if filter_keywords.include?(display_name_lower)
                tag_matched = true
                matched_keyword = display_name_lower
              else
                matched_keyword = filter_keywords.find { |keyword| display_name_lower.include?(keyword) }
                tag_matched = true if matched_keyword
              end
            end
            
            # Collect matches
            if tag_matched
              matches << {
                tag: tag,
                keyword: matched_keyword,
                current_banned: tag.is_banned
              }
            end
            
          rescue => e
            error_count += 1
            puts "Error processing tag ID #{tag.id}: #{e.message}"
            Rails.logger.error "Error in preview_banned_tags for tag #{tag.id}: #{e.message}"
          end
        end
        
        # Progress update for large datasets
        puts "Processed #{processed_count} tags..." if processed_count % 5000 == 0
      end
      
      # Sort matches for better readability
      matches.sort_by! { |m| [m[:current_banned] ? 0 : 1, m[:tag].name] }
      
      puts "\nFound #{matches.count} tags that match keyword filters:"
      
      # Limit output for readability
      display_limit = 100
      matches.first(display_limit).each do |match|
        status = match[:current_banned] ? "[ALREADY BANNED]" : "[WOULD BE BANNED]"
        puts "  #{status} Tag: '#{match[:tag].name}' (ID: #{match[:tag].id}) - Matches: '#{match[:keyword]}'"
      end
      
      if matches.count > display_limit
        puts "  ... and #{matches.count - display_limit} more matches (showing first #{display_limit})"
      end
      
      new_bans = matches.reject { |m| m[:current_banned] }.count
      already_banned = matches.select { |m| m[:current_banned] }.count
      
      end_time = Time.current
      duration = (end_time - start_time).round(2)
      
      puts "\n" + "="*50
      puts "PREVIEW SUMMARY:"
      puts "Total tags processed: #{processed_count}"
      puts "Total matches found: #{matches.count}"
      puts "Already banned: #{already_banned}"
      puts "Would be newly banned: #{new_bans}"
      puts "Errors encountered: #{error_count}"
      puts "Duration: #{duration} seconds"
      puts "="*50
      
    rescue => e
      puts "Fatal error in preview_banned_tags: #{e.message}"
      Rails.logger.error "Fatal error in preview_banned_tags: #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end
  
  desc 'Reset banned status for all tags (use with caution)'
  task reset_banned_tags: :environment do
    puts "WARNING: This will reset is_banned to false for ALL tags!"
    puts "Type 'CONFIRM' to proceed:"
    
    input = STDIN.gets.chomp
    if input == 'CONFIRM'
      start_time = Time.current
      puts "Resetting banned status for all tags..."
      
      begin
        count = Tag.where(  ).count
        puts "Found #{count} banned tags to reset"

        Tag.where(usable: true, listable: true, trendable: true).find_in_batches(batch_size: 1000) do |batch|
          batch.each { |tag| tag.update!(usable: false, listable: false, trendable: false) }
          puts "Reset #{batch.size} tags..."
        end
        
        duration = (Time.current - start_time).round(2)
        puts "Finished! Reset #{count} tags in #{duration} seconds."
        
      rescue => e
        puts "Error resetting banned tags: #{e.message}"
        Rails.logger.error "Error in reset_banned_tags: #{e.message}\n#{e.backtrace.join("\n")}"
        raise
      end
    else
      puts "Operation cancelled."
    end
  end
end
