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
    Dir["{app,config,db,lib,bin}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.1"
  
end

# Hook that runs after the gem is installed
# Gem.post_install do |installer|
#   if installer.spec.name == "content_filters"
#     puts "Content Filters gem installed! Attempting to copy Chewy index files..."
    
#     # Check if we can run the rake task directly
#     if system("cd #{Dir.pwd} && bundle exec rake content_filters:install RAILS_ENV=development")
#       puts "✅ Chewy index files successfully copied to your application!"
#     else
#       puts "⚠️  Could not run rake task directly. This is normal during initial installation."
#       puts "The files will be copied when you first run your Rails application."
#       puts "You can also manually copy them later with: bundle exec rake content_filters:install"
      
#       # Try to find a way to copy the files anyway
#       begin
#         require 'fileutils'
        
#         # Get source path
#         gem_root = installer.gem_dir
#         source_path = File.join(gem_root, "app", "chewy", "content_filters")
        
#         # Try to guess the Rails root (current directory might be it)
#         app_root = Dir.pwd
#         destination_path = File.join(app_root, "app", "chewy")
        
#         # Create destination directory if it doesn't exist
#         FileUtils.mkdir_p(destination_path)
        
#         # Copy files
#         if Dir.exist?(source_path)
#           puts "Copying Chewy index files directly..."
          
#           # Find all files in the source directory
#           Dir.glob(File.join(source_path, "*.rb")).each do |file|
#             # Get just the filename
#             filename = File.basename(file)
            
#             # Copy to the destination directory
#             FileUtils.cp(file, File.join(destination_path, filename))
#             puts "  - Copied #{filename}"
#           end
          
#           puts "✅ Chewy index files have been successfully copied to #{destination_path}/"
#         end
#       rescue => e
#         puts "Could not copy files directly: #{e.message}"
#       end
#     end
#   end
# end
