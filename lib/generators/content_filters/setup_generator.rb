# lib/generators/content_filters/setup_generator.rb
module ContentFilters
  module Generators
    class SetupGenerator < Rails::Generators::Base
      desc "Set up content filters by running rake tasks"
      
      def run_setup_tasks
        say "Running content filters setup tasks...", :green
        
        begin
          # Run the install task
          rake "content_filters:install"
          
          # Create marker file
          create_marker_file
          
          say "Content filters setup completed!", :green
        rescue => e
          say "Error during setup: #{e.message}", :red
          raise
        end
      end
      
      private
      
      def create_marker_file
        marker_path = Rails.root.join('.content_filters_installed')
        create_file marker_path, "Content filters installed at #{Time.current}\n"
      end
    end
  end
end