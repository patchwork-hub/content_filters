# frozen_string_literal: true

namespace :content_filters do
  desc 'Check accounts against keyword filters and update banned status'
  task update_banned_accounts: :environment do
    start_time = Time.current
    puts "Starting to check accounts against keyword filters at #{start_time}..."
    
    begin
      # Get all keyword filters (all filter types)
      keyword_filters = ContentFilters::KeywordFilter.all
      
      if keyword_filters.empty?
        puts "No keyword filters found. Exiting."
        return
      end
      
      puts "Found #{keyword_filters.count} keyword filters to check against"
      
      # Create Set of normalized keywords for O(1) lookup performance
      filter_keywords = Set.new(keyword_filters.pluck(:keyword).map do |keyword|
        # Normalize keyword: remove '#', convert to lowercase, and strip whitespace
        keyword.to_s.downcase.strip.gsub('#', '')
      end.reject(&:blank?))
      
      puts "Normalized #{filter_keywords.size} unique keywords for matching"
      
      banned_count = 0
      error_count = 0
      processed_count = 0
      batch_size = 1000
      
      # Use select to only load necessary columns for better performance
      total_accounts = Account.count
      puts "Checking #{total_accounts} accounts in batches of #{batch_size}..."
      
      # Process accounts in batches for better performance
      Account.select(:id, :username, :display_name, :note, :is_banned).find_in_batches(batch_size: batch_size) do |account_batch|
        # Collect all account IDs that need to be banned in this batch
        accounts_to_ban = []
        
        account_batch.each do |account|
          processed_count += 1
          
          begin
            next if account.is_banned # Skip already banned accounts
            
            account_matched = false
            matched_keyword = nil
            
            # Check if any account attribute matches any normalized keyword
            filter_keywords.each do |normalized_keyword|
              if account_contains_keyword?(account, normalized_keyword)
                account_matched = true
                matched_keyword = normalized_keyword
                break
              end
            end
            
            if account_matched
              accounts_to_ban << {
                id: account.id,
                username: account.username,
                keyword: matched_keyword
              }
              puts "Found account to ban: '#{account.username}' (ID: #{account.id}) - Matches: '#{matched_keyword}'"
            end
            
          rescue => e
            error_count += 1
            puts "Error processing account ID #{account.id}: #{e.message}"
            Rails.logger.error "Error in update_banned_accounts for account #{account.id}: #{e.message}\n#{e.backtrace.join("\n")}"
          end
        end
        
        # Batch update for better performance
        if accounts_to_ban.any?
          begin
            account_ids = accounts_to_ban.map { |a| a[:id] }
            Account.where(id: account_ids).find_each do |account|
              matched_info = accounts_to_ban.find { |a| a[:id] == account.id }
              Rails.logger.info "#{'>'*8}Account: #{account.id} (#{account.username}) has been banned due to keyword: #{matched_info[:keyword]}.#{'<'*8}"
              account.update!(is_banned: true)
              banned_count += 1
            end
            puts "Batch updated #{accounts_to_ban.size} accounts to banned status"
          rescue => e
            puts "Error in batch update: #{e.message}"
            Rails.logger.error "Batch update error in update_banned_accounts: #{e.message}\n#{e.backtrace.join("\n")}"
            
            # Fallback to individual updates
            accounts_to_ban.each do |account_info|
              begin
                account = Account.find(account_info[:id])
                Rails.logger.info "#{'>'*8}Account: #{account.id} (#{account.username}) has been banned due to keyword: #{account_info[:keyword]}.#{'<'*8}"
                account.update!(is_banned: true)
                banned_count += 1
              rescue => e
                error_count += 1
                puts "Error updating account ID #{account_info[:id]}: #{e.message}"
                Rails.logger.error "Individual update error for account #{account_info[:id]}: #{e.message}"
              end
            end
          end
        end
        
        # Progress update
        puts "Processed #{processed_count}/#{total_accounts} accounts (#{(processed_count.to_f / total_accounts * 100).round(2)}%)"
      end
      
      end_time = Time.current
      duration = (end_time - start_time).round(2)
      
      puts "\n" + "="*50
      puts "SUMMARY:"
      puts "Total accounts processed: #{processed_count}"
      puts "Accounts updated to banned: #{banned_count}"
      puts "Errors encountered: #{error_count}"
      puts "Duration: #{duration} seconds"
      puts "Average: #{(processed_count.to_f / duration).round(2)} accounts/second"
      puts "="*50
      
    rescue => e
      puts "Fatal error in update_banned_accounts: #{e.message}"
      Rails.logger.error "Fatal error in update_banned_accounts: #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end
  
  desc 'Check accounts against keyword filters and show matches without updating'
  task preview_banned_accounts: :environment do
    start_time = Time.current
    puts "Previewing accounts that would be banned..."
    
    begin
      # Get all keyword filters (all filter types)
      keyword_filters = ContentFilters::KeywordFilter.all
      
      if keyword_filters.empty?
        puts "No keyword filters found. Exiting."
        return
      end
      
      puts "Found #{keyword_filters.count} keyword filters:"
      keyword_filters.each do |filter|
        puts "  - '#{filter.keyword}' (#{filter.filter_type})"
      end
      puts ""
      
      # Create Set of normalized keywords for O(1) lookup performance
      filter_keywords = Set.new(keyword_filters.pluck(:keyword).map do |keyword|
        keyword.to_s.downcase.strip.gsub('#', '')
      end.reject(&:blank?))
      
      puts "Normalized #{filter_keywords.size} unique keywords for matching\n"
      
      matches = []
      processed_count = 0
      error_count = 0
      batch_size = 1000
      
      # Process in batches for better memory management
      Account.select(:id, :username, :display_name, :note, :is_banned).find_in_batches(batch_size: batch_size) do |account_batch|
        account_batch.each do |account|
          processed_count += 1
          
          begin
            account_matched = false
            matched_keyword = nil
            
            # Check if any account attribute matches any normalized keyword
            filter_keywords.each do |normalized_keyword|
              if account_contains_keyword?(account, normalized_keyword)
                account_matched = true
                matched_keyword = normalized_keyword
                break
              end
            end
            
            # Collect matches
            if account_matched
              matches << {
                account: account,
                keyword: matched_keyword,
                current_banned: account.is_banned
              }
            end
            
          rescue => e
            error_count += 1
            puts "Error processing account ID #{account.id}: #{e.message}"
            Rails.logger.error "Error in preview_banned_accounts for account #{account.id}: #{e.message}"
          end
        end
        
        # Progress update for large datasets
        puts "Processed #{processed_count} accounts..." if processed_count % 5000 == 0
      end
      
      # Sort matches for better readability
      matches.sort_by! { |m| [m[:current_banned] ? 0 : 1, m[:account].username] }
      
      puts "\nFound #{matches.count} accounts that match keyword filters:"
      
      # Limit output for readability
      display_limit = 100
      matches.first(display_limit).each do |match|
        status = match[:current_banned] ? "[ALREADY BANNED]" : "[WOULD BE BANNED]"
        puts "  #{status} Account: '#{match[:account].username}' (ID: #{match[:account].id}) - Matches: '#{match[:keyword]}'"
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
      puts "Total accounts processed: #{processed_count}"
      puts "Total matches found: #{matches.count}"
      puts "Already banned: #{already_banned}"
      puts "Would be newly banned: #{new_bans}"
      puts "Errors encountered: #{error_count}"
      puts "Duration: #{duration} seconds"
      puts "="*50
      
    rescue => e
      puts "Fatal error in preview_banned_accounts: #{e.message}"
      Rails.logger.error "Fatal error in preview_banned_accounts: #{e.message}\n#{e.backtrace.join("\n")}"
      raise
    end
  end
  
  desc 'Reset banned status for all accounts (use with caution)'
  task reset_banned_accounts: :environment do
    puts "WARNING: This will reset is_banned to false for ALL accounts!"
    puts "Type 'CONFIRM' to proceed:"
    
    input = STDIN.gets.chomp
    if input == 'CONFIRM'
      start_time = Time.current
      puts "Resetting banned status for all accounts..."
      
      begin
        count = Account.where(is_banned: true).count
        puts "Found #{count} banned accounts to reset"
        
        Account.where(is_banned: true).find_in_batches(batch_size: 1000) do |batch|
          batch.each { |account| account.update!(is_banned: false) }
          puts "Reset #{batch.size} accounts..."
        end
        
        duration = (Time.current - start_time).round(2)
        puts "Finished! Reset #{count} accounts in #{duration} seconds."
        
      rescue => e
        puts "Error resetting banned accounts: #{e.message}"
        Rails.logger.error "Error in reset_banned_accounts: #{e.message}\n#{e.backtrace.join("\n")}"
        raise
      end
    else
      puts "Operation cancelled."
    end
  end

  private

  # Helper method to check if account contains keyword in any of its attributes
  def account_contains_keyword?(account, keyword)
    return false unless account && keyword.present?

    # Normalize keyword for case-insensitive comparison
    normalized_keyword =  keyword.to_s.downcase.strip.gsub('#', '')

    # Create regex pattern for exact word matching
    # \b ensures word boundaries (beginning and end of word)
    word_pattern = /\b#{Regexp.escape(normalized_keyword)}\b/i

    # Safely check each field with null protection and exact word matching
    username_match = account.username&.match?(word_pattern)
    display_name_match = account.display_name&.match?(word_pattern)
    note_match = account.note&.match?(word_pattern)

    # Return true if keyword is found as a complete word in any field
    username_match || display_name_match || note_match
  end
end
