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

      rake_tasks do
        namespace :content_filters do
          # desc "Copies migrations from ContentFilters engine"
          # task :migrations do
          # Rake::Task["railties:install:migrations"].invoke
          # end

          desc "Installs the ContentFilters engine"
          task setup: :environment do
            puts "Running ContentFilters installation tasks..."
            task :without_env do
              Rake::Task["content_filters:install:"].invoke
            end
          end
        end
      end

    end
  end