# lib/generators/content_filters/install_generator.rb
module ContentFilters
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install content filters (required for app startup)"
      
      def install_content_filters
        say "Installing content filters...", :green
        
        # Create marker file FIRST to prevent race conditions
        create_marker_file
        
        # Add marker file to .gitignore
        add_to_gitignore
        
        # Run the install rake task
        rake "content_filters:install"
        
        say "Content filters installed successfully!", :green
        say "Your Rails application can now start normally.", :yellow
      end
      
      private
      
      def create_marker_file
        marker_path = Rails.root.join('.content_filters_installed')
        create_file marker_path, <<~CONTENT
          # This file indicates that content_filters generator has been run
          # Generated at: #{Time.current}
          # Do not delete this file unless you want to re-run the generator
        CONTENT
      end
      
      def add_to_gitignore
        gitignore_path = Rails.root.join('.gitignore')
        marker_entry = '.content_filters_installed'
        
        # Check if .gitignore exists
        if File.exist?(gitignore_path)
          gitignore_content = File.read(gitignore_path)
          
          # Check if the entry is already in .gitignore
          unless gitignore_content.include?(marker_entry)
            say "Adding #{marker_entry} to .gitignore", :yellow
            
            # Add a comment and the entry to .gitignore
            append_to_file gitignore_path, <<~GITIGNORE
              
              # Content filters installation marker
              #{marker_entry}
            GITIGNORE
          else
            say "#{marker_entry} already exists in .gitignore", :blue
          end
        else
          say "Creating .gitignore and adding #{marker_entry}", :yellow
          create_file gitignore_path, <<~GITIGNORE
            # Content filters installation marker
            #{marker_entry}
          GITIGNORE
        end
      end
    end
  end
end