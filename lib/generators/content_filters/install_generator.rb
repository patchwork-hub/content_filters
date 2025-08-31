# lib/generators/content_filters/install_generator.rb
module ContentFilters
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install content filters (required for app startup)"
      
      def install_content_filters
        say "Installing content filters...", :green
        
        # Run the install rake task
        rake "content_filters:install"
        
        # Create a marker file to indicate generator has been run
        create_marker_file
        
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
    end
  end
end