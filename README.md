# Content Filters

Easily manage your Mastodon server timelines by blocking or unblocking specific Threads and Bluesky posts, and filter your timelines by blocking posts with specific hashtags and keywords.

Content Filters is a Patchwork plugin that provides advanced content filtering and moderation capabilities for your Mastodon server timelines. This gem integrates seamlessly with the Patchwork Dashboard to give administrators powerful tools to control what content appears in feeds, manage spam, and moderate accounts automatically based on configurable rules.

## Prerequisites

Before installing this gem, ensure the following systems are installed and running:

- [Mastodon server](https://docs.joinmastodon.org/admin/install/) - A working Mastodon instance (Rails 7.1+ compatible)
- [Patchwork Dashboard](https://github.com/patchwork-hub/patchwork_dashboard) - The main Patchwork management interface

For complete setup instructions, see the [Patchwork Dashboard README](https://github.com/patchwork-hub/patchwork_dashboard/blob/main/README.md).

## Installation

1. Add this line to your Mastodon application's Gemfile:

```ruby
gem "content_filters", git: "https://github.com/patchwork-hub/content_filters"
```

1. Install the gem:

```bash
bundle install
```

1. Run the installation task to copy Chewy index files:

```bash
bundle exec rake content_filters:install
```

1. Run database migrations:

```bash
rails db:migrate
```

1. Restart your Mastodon application:

```bash
systemctl restart mastodon-web
systemctl restart mastodon-sidekiq
```

## Features

### 🛡️ Content Moderation & Filtering

- **Keyword Filtering**: Block posts containing specific keywords across different timeline types (hashtag, text, or both)
- **Hashtag Filtering**: Filter content based on hashtags with exact matching
- **Account Banning**: Automatically ban accounts based on username, display name, or bio content matching filter keywords
- **Status Banning**: Automatically mark statuses as banned and sensitive when they match filter criteria
- **Tag Banning**: Automatically mark tags as non-listable and non-trendable when they match filters
- **Spam Detection**: Separate spam filters with dedicated detection and blocking capabilities
- **Real-time Processing**: Background workers continuously monitor and apply filters to new content

### 🌐 Federation Controls

- **Threads Integration**: Block or unblock posts from Threads from appearing in timelines
- **Bluesky Integration**: Control Bluesky post visibility in your server's feeds
- **Domain Filtering**: Filter statuses based on server settings and federation policies
- **Cross-platform Content Management**: Fine-grained control over federated content

### 🤖 Community Channel Automation

- **Automated Reblogging**: Automatically boost posts to community channels based on filter rules
- **Newsmast Bot Integration**: Support for Newsmast-specific boosting via Lambda service
- **Custom Channel Support**: Configure boost behavior for custom community channels
- **Group Channel Management**: Manage group channels with automated boosting
- **Filter-based Boosting**: Only boost posts that pass community-specific keyword filters

### 📊 Advanced Search Capabilities

- **Account Search Enhancement**: Enhanced account search with `is_banned` filtering
- **Banned Content Exclusion**: Search results automatically exclude banned accounts and statuses
- **Following Network Search**: Advanced search for accounts within your following network
- **Elasticsearch Integration**: Custom Chewy indices for accounts, statuses, and public statuses

### 🔧 Filter Management

- **Global Filters**: Server-wide keyword filters that apply to all users
- **Community Filters**: Community-specific filters with filter-in and filter-out support
- **Filter Types**: Support for hashtag-only, text-only, or combined filtering
- **Redis Caching**: Efficient filter caching with 24-hour expiration
- **Multiple Filter Sources**: Combine ContentFilters::KeywordFilter and ContentFilters::CommunityFilterKeyword

### 📈 Performance Optimizations

- **Batch Processing**: Process accounts, statuses, and tags in configurable batches (default 1000)
- **Redis Integration**: Fast banned content ID lookups using Redis sorted sets
- **Database Read Replicas**: Support for read replica routing for heavy queries
- **Selective Column Loading**: Load only necessary columns for better performance
- **Progress Tracking**: Real-time progress logging during batch operations

### 🔍 Timeline Filtering

- **Home Timeline Filtering**: Filter home feed based on content filters and server settings
- **Public Timeline Filtering**: Enhanced public feed with reblog and reply filtering options
- **Excluded Status IDs**: Maintain separate Redis sets for content filters and spam filters
- **Direct Status Exclusion**: Option to exclude direct messages from timelines
- **Followed Tags Filtering**: Control visibility of posts from followed hashtags
- **Reply Filtering**: Option to exclude replies from feed

### 🎯 Feed Service Integration

- **Server Setting Aware**: Automatically apply filters based on server configuration
- **Federation Filtering**: Filter content based on Threads and Bluesky server settings
- **Dynamic Filter Application**: Apply content filters and spam filters independently or together
- **Cache Management**: Efficient banned status ID management in Redis

## Configuration

### Environment Variables

- `LOCAL_DOMAIN` - Your Mastodon server's domain (required for reblog operations)
- `MAIN_CHANNEL` - Enable/disable main channel reblogging functionality
- `BOOST_BOT_ENABLED` - Enable/disable automated boost bot
- `BOOST_COMMUNITY_BOT_URL` - URL for Newsmast bot Lambda service
- `BOOST_COMMUNITY_BOT_API_KEY` - API key for Newsmast bot authentication
- `FOR_YOU_TIMELINE_CHANNELS` - Optional comma-separated list of community bot usernames that should trigger custom boost bot calls (example: `sports,news,tech`)
- `<CHANNEL_USERNAME_UPPERCASE>_INSTANCE_URL` - Optional custom boost bot instance base URL for a specific channel username (example: `SPORTS_INSTANCE_URL`)
- `<CHANNEL_USERNAME_UPPERCASE>_CLIENT_ID` - Optional custom boost bot client ID for a specific channel username (example: `SPORTS_CLIENT_ID`)
- `<CHANNEL_USERNAME_UPPERCASE>_CLIENT_SECRET` - Optional custom boost bot client secret for a specific channel username (example: `SPORTS_CLIENT_SECRET`)

### Database Migrations

The gem adds the following database columns:

- `accounts.is_banned` - Boolean flag for banned accounts (default: false)
- `statuses.is_banned` - Boolean flag for banned statuses (default: false)

### Redis Keys

The gem uses the following Redis keys:

- `excluded_status_ids` - Combined banned status IDs (content + spam filters)
- `content_filters_banned_status_ids` - Status IDs banned by content filters
- `spam_filters_banned_status_ids` - Status IDs banned by spam filters
- `spam_filters` / `channel:spam_filters` - Hash of spam filter configurations
- `content_filters` / `channel:content_filters` - Hash of content filter configurations

## Background Workers

### BanTagWorker

Checks tags against keyword filters and updates banned status:

```ruby
BanTagWorker.perform_async
```

### AccountBannedWorker

Checks accounts against keyword filters and bans matching accounts:

```ruby
AccountBannedWorker.perform_async
```

### StatusBannedWorker

Checks statuses against keyword filters and marks them as banned:

```ruby
StatusBannedWorker.perform_async
```

### BanStatusWorker

Checks individual status and applies banning or reblogging based on filters:

```ruby
BanStatusWorker.perform_async(status_id)
```

### ReblogChannelsWorker

Handles automated reblogging to community channels:

```ruby
ReblogChannelsWorker.perform_async(status_id, account_id)
```

## Rake Tasks

### Content Filters Management

```bash
# Check and update banned accounts
rake content_filters:update_banned_accounts

# Preview accounts that would be banned (no changes)
rake content_filters:preview_banned_accounts

# Reset all banned accounts (use with caution)
rake content_filters:reset_banned_accounts

# Update banned tags
rake content_filters:update_banned_tags

# Install Chewy index files
rake content_filters:install
```

## Usage

### Setting up Keyword Filters

1. Access the Content Filters section in your Patchwork Dashboard
2. Add keywords or phrases to block
3. Choose filter type: hashtag, text, or both
4. Set whether filters are active
5. Configure community-specific filters if needed

### Managing Federation Controls

1. Navigate to Server Settings in the dashboard
2. Enable/disable Threads integration
3. Configure Bluesky post visibility
4. Set federation policies

### Monitoring Banned Content

The gem automatically:

- Marks banned statuses as sensitive with spoiler text
- Sets banned accounts' statuses as banned
- Updates tag listability and trendability
- Maintains Redis caches of banned content IDs
- Logs all banning operations for audit purposes

### Account Search Integration

The gem enhances account search by:

- Excluding banned accounts from search results
- Supporting advanced search within following networks
- Providing exact word matching for filter keywords
- Integrating with Elasticsearch via Chewy indices

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

```bash
git clone https://github.com/patchwork-hub/content_filters.git
cd content_filters
bundle install
bundle exec rake test  # Run tests
```

## Support

- 📖 [Documentation](https://docs.joinpatchwork.org/)
- 🐛 [Report Issues](https://github.com/patchwork-hub/content_filters/issues)
- 💬 [Community Discussions](https://github.com/patchwork-hub/patchwork_dashboard/discussions)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Bug reports and pull requests are welcome on GitHub at <https://github.com/patchwork-hub/content_filters>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/patchwork-hub/content_filters/blob/main/CODE_OF_CONDUCT.md).

## License

This gem is available as open source under the terms of the [AGPL-3.0 License](LICENSE.txt).

## Code of Conduct

Everyone interacting in the Content Filters project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/patchwork-hub/content_filters/blob/main/CODE_OF_CONDUCT.md).

## About Patchwork

Patchwork is an open-source project aimed at enhancing Mastodon servers with additional functionality and improved user experience. Learn more at [joinpatchwork.org](https://www.joinpatchwork.org/).
