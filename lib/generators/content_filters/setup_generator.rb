# lib/generators/content_filters/setup_generator.rb
module ContentFilters
  module Generators
    class SetupGenerator < Rails::Generators::Base
      desc "Set up content filters by running rake tasks"
      
      def run_setup_tasks
        say "Running content filters setup tasks...", :green
        
        # Run the install task
        rake "content_filters:install"
        
        say "Content filters setup completed!", :green
      end
    end
  end
end