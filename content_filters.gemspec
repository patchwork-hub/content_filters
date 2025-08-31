require_relative "lib/content_filters/version"

Gem::Specification.new do |spec|
  spec.name        = "content_filters"
  spec.version     = ContentFilters::VERSION
  spec.authors     = ["Aung Kyaw Phyo"]
  spec.email       = ["kiru.kiru28@gmail.com"]
  spec.homepage    = "https://www.joinpatchwork.org/"
  spec.summary     = "Easily manage your timelines by blocking or unblocking specific Threads and Bluesky posts, and filter your timelines by blocking posts with specific hashtags and keywords."
  spec.description = "Easily manage your timelines by blocking or unblocking specific Threads and Bluesky posts, and filter your timelines by blocking posts with specific hashtags and keywords."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.1"
  
end
