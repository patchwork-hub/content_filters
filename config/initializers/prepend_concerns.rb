Rails.application.config.to_prepare do
    Feed.prepend(ContentFilters::Concerns::FeedConcern)
    Status.include(ContentFilters::Concerns::StatusConcern)
    PublicFeed.prepend(ContentFilters::Concerns::PublicFeedConcern)
    Account.include(ContentFilters::Concerns::AccountConcern)
    Account.include(ContentFilters::Concerns::AccountSearchConcern)
    Tag.prepend(ContentFilters::Concerns::TagConcern)
    User.include(ContentFilters::Concerns::UserConcern)
    TagSearchService.prepend(ContentFilters::Concerns::TagSearchService)
    Api::V1::Timelines::HomeController.prepend(ContentFilters::Overrides::HomeExtendedTimeline)
end