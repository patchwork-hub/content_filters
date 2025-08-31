module ContentFilters
  class Railtie < ::Rails::Railtie
    rake_tasks do
      path = File.expand_path('../../tasks/content_filters_install.rake', __dir__)
      load path if File.exist?(path)
    end
  end
end

