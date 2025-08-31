# frozen_string_literal: true

require 'fileutils'

namespace :content_filters do
  desc "Copy Chewy index files from content_filters gem to the main application"
  task :install do
    # Get source path
    gem_root = Gem.loaded_specs["content_filters"].full_gem_path
    source_path = File.join(gem_root, "app", "chewy", "content_filters")
    
    # Get destination path
    destination_path = Rails.root.join("app", "chewy")
    
    # Create destination directory if it doesn't exist
    FileUtils.mkdir_p(destination_path)
    
    # Copy files
    if Dir.exist?(source_path)
      puts "Copying Chewy index files from content_filters gem..."
      
      # Find all files in the source directory
      Dir.glob(File.join(source_path, "*.rb")).each do |file|
        # Get just the filename
        filename = File.basename(file)
        
        # Copy to the destination directory
        FileUtils.cp(file, File.join(destination_path, filename))
        puts "  - Copied #{filename}"
      end
      
      puts "Chewy index files have been successfully copied to #{destination_path}/"
      
      # Create marker file after successful installation
      create_marker_file
      
      puts "Content filters installation completed successfully!"
      puts "Your Rails application can now start normally."
      
    else
      puts "Error: Source directory #{source_path} not found!"
      exit(1)
    end
  end
  
  private
  
  def create_marker_file
    marker_path = Rails.root.join('.content_filters_installed')
    File.write(marker_path, <<~CONTENT)
      # This file indicates that content_filters has been installed
      # Generated at: #{Time.current}
      # Do not delete this file unless you want to re-run the installation
    CONTENT
    puts "Created installation marker file: .content_filters_installed"
  end
end
