module ContentFilters
    class Engine < ::Rails::Engine
      isolate_namespace ContentFilters

      initializer :append_migrations do |app|
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end

      initializer 'content_filters.load_routes' do |app|
        app.routes.prepend do
          mount ContentFilters::Engine => "/", :as => :content_filters
        end
      end

      config.autoload_paths << File.expand_path("../app/services", __FILE__)
      config.autoload_paths << File.expand_path("../app/workers", __FILE__)

      config.generators do |g|
        g.test_framework :rspec
      end

      # Add generator paths
      config.generators.templates_path = File.expand_path('../generators/templates', __dir__)

      # Enforce generator execution before app startup
      initializer 'content_filters.enforce_generator_execution', before: :load_config_initializers do |app|
        # Only enforce in non-test environments and when Rails is fully loaded
        next if Rails.env.test? || defined?(Rails::Console)
        
        marker_file = app.root.join('.content_filters_installed')
        
        unless marker_file.exist?
          error_message = <<~ERROR
          
            ================================================================
            CONTENT FILTERS SETUP REQUIRED
            ================================================================
            
            The content_filters gem requires initial setup before the 
            application can start.
            
            Please run the following command:
            
              rails generate content_filters:install
            
            This will install required Chewy index files and configure
            the content filtering system.
            
            ================================================================
            
          ERROR
          
          Rails.logger.error(error_message) if Rails.logger
          puts error_message
          
          # Prevent the application from starting
          raise "Content filters setup required. Run: rails generate content_filters:install"
        end
      end
    end
  end