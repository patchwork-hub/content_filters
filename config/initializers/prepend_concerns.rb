Rails.application.config.to_prepare do
    Feed.prepend(ContentFilters::Concerns::FeedConcern)
    Status.include(ContentFilters::Concerns::StatusConcern)
    PublicFeed.prepend(ContentFilters::Concerns::PublicFeedConcern)
    Account.include(ContentFilters::Concerns::AccountConcern)
    User.include(ContentFilters::Concerns::UserConcern)
end