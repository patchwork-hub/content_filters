require "rubygems/installer"
 
Gem.post_install do |installer|
  if installer.spec.name == "content_filters"
    # Run rake task after install
    puts 'Running content_filters:install rake task...'
    system("bundle exec rake content_filters:install")
  end
end