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
    end
  end