Rails.application.config.to_prepare do
    Feed.prepend(ContentFilters::Concerns::FeedConcern)
    Status.include(ContentFilters::Concerns::StatusConcern)
    PublicFeed.prepend(ContentFilters::Concerns::PublicFeedConcern)
    Account.include(ContentFilters::Concerns::AccountConcern)
    Tag.prepend(ContentFilters::Concerns::TagConcern)
    User.include(ContentFilters::Concerns::UserConcern)
    TagSearchService.prepend(ContentFilters::Concerns::TagSearchService)
    # StatusesIndex.prepend(ContentFilters::Concerns::StatusesIndexOverride)
    # PublicStatusesIndex.prepend(ContentFilters::Concerns::PublicStatusesIndexOverride)
    # AccountsIndex.prepend(ContentFilters::Concerns::AccountsIndexOverride)
    # TagsIndex.prepend(ContentFilters::Concerns::TagsIndexOverride)
end