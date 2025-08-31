# lib/generators/content_filters/reset_generator.rb
module ContentFilters
  module Generators
    class ResetGenerator < Rails::Generators::Base
      desc "Reset content filters installation state"
      
      def reset_installation
        marker_file = Rails.root.join('.content_filters_installed')
        
        if marker_file.exist?
          remove_file marker_file
          say "Content filters installation state reset.", :yellow
          say "You will need to run 'rails generate content_filters:install' before starting the app.", :yellow
        else
          say "Content filters was not previously installed.", :green
        end
      end
    end
  end
end