module ContentFilters
    class Engine < ::Rails::Engine
      isolate_namespace ContentFilters

      # Exclude app/chewy from autoloading to prevent conflicts
      config.autoload_paths.reject! { |path| path.to_s.include?('app/chewy') }
      config.eager_load_paths.reject! { |path| path.to_s.include?('app/chewy') }

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

      # Prevent gem's app/chewy files from being autoloaded
      initializer 'content_filters.exclude_chewy_autoload', before: :set_autoload_paths do |app|
        # Remove any chewy paths that might have been added
        gem_chewy_path = File.expand_path("../app/chewy", __FILE__)
        
        config.autoload_paths.delete(gem_chewy_path)
        config.eager_load_paths.delete(gem_chewy_path)
        
        # Also exclude from Rails default paths
        config.paths.add "app/chewy", with: []
      end

      # Enforce rake task execution before app startup
      initializer 'content_filters.enforce_rake_execution', before: :load_environment_config do |app|
        # Only enforce in specific environments and contexts
        next if Rails.env.test?
        next if defined?(Rails::Console)
        
        # Check if we're running rake tasks or other commands
        next if ARGV.any? { |arg| 
          arg.match?(/\A(rake|db:|assets:|routes|notes|stats|middleware|runner|generate|g|destroy)\b/)
        }
        
        # Only check when starting the web server
        next unless ARGV.empty? || ARGV.any? { |arg| arg.match?(/\A(server|s)\z/) }
        
        marker_file = app.root.join('.content_filters_installed')
        
        unless marker_file.exist?
          error_message = <<~ERROR
        
            ================================================================
            CONTENT FILTERS SETUP REQUIRED
            ================================================================
            
            The content_filters gem requires initial setup before the 
            application can start.
            
            Please run the following command:
            
              bundle exec rake content_filters:install
            
            This will copy required Chewy index files and configure
            the content filtering system.
            
            ================================================================
            
          ERROR
          
          Rails.logger&.error(error_message)
          puts error_message
          
          # Prevent the application from starting
          exit(1)
        end
      end
    end
  end