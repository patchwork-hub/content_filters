module ContentFilters
    class Engine < ::Rails::Engine
      isolate_namespace ContentFilters
      
      config.autoload_paths << File.expand_path("../app/workers/content_filters", __FILE__)
    end
  end