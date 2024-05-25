Rails.application.config.to_prepare do
    Feed.prepend(ContentFilters::TimelineFilter)
end