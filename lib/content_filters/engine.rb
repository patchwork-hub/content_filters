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

      # Enforce generator execution before app startup - IMPROVED VERSION
      initializer 'content_filters.enforce_generator_execution', before: :load_environment_config do |app|
        # Only enforce in specific environments and contexts
        next if Rails.env.test?
        next if defined?(Rails::Console)
        next if defined?(Rails::Command::GenerateCommand)
        next if defined?(Rails::Command::RakeCommand)
        
        # Check if we're running generators or rake tasks
        next if ARGV.any? { |arg| 
          arg.match?(/\A(generate|g|rake|db:|assets:|routes|notes|stats|middleware|runner|destroy)\b/)
        }
        
        # Skip if running specific Rails commands
        next if $0.match?(/\b(rake|rails)\z/)
        
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
            
              rails generate content_filters:install
            
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