# frozen_string_literal: true

require 'fileutils'

namespace :content_filters do
  desc "Copy Chewy index files from content_filters gem to the main application"
  task :install do
    # Check if we're in a Rails environment
    if defined?(Rails) && Rails.respond_to?(:root)
      Rake::Task["content_filters:install:with_env"].invoke
    else
      # We're not in a Rails environment, so we need to handle it differently
      Rake::Task["content_filters:install:without_env"].invoke
    end
  end
  
  namespace :install do
    # Task that runs in a Rails environment
    task with_env: :environment do
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
      else
        puts "Error: Source directory #{source_path} not found!"
      end
    end
    
    # Task that runs outside a Rails environment
    task :without_env do
      # Try to guess the gem root
      gem_root = nil
      
      # Try to find the content_filters gem
      if defined?(Gem) && Gem.loaded_specs["content_filters"]
        gem_root = Gem.loaded_specs["content_filters"].full_gem_path
      else
        # Try to find it relative to the current file
        current_file = File.expand_path(__FILE__)
        possible_root = File.expand_path('../../..', current_file)
        if File.directory?(File.join(possible_root, 'app', 'chewy', 'content_filters'))
          gem_root = possible_root
        end
      end
      
      if gem_root.nil?
        puts "Error: Could not find content_filters gem!"
        exit(1)
      end
      
      source_path = File.join(gem_root, "app", "chewy", "content_filters")
      
      # Try to guess the Rails root (current directory might be it)
      app_root = Dir.pwd
      destination_path = File.join(app_root, "app", "chewy")
      
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
      else
        puts "Error: Source directory #{source_path} not found!"
      end
    end
  end
end
