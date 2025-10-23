# Content Filters

Easily manage your timelines by blocking or unblocking specific Threads and Bluesky posts, and filter your timelines by blocking posts with specific hashtags and keywords.

## Overview

Content Filters is a Patchwork plugin that provides advanced content filtering capabilities for your Mastodon server timelines. This gem integrates seamlessly with the Patchwork Dashboard to give administrators and users powerful tools to control what content appears in their feeds.

## Prerequisites

Before installing this gem, ensure the following systems are installed and running:

- [Mastodon server](https://docs.joinmastodon.org/admin/install/) - A working Mastodon instance
- [Patchwork Dashboard](https://github.com/patchwork-hub/patchwork_dashboard) - The main Patchwork management interface

For complete setup instructions, see the [Patchwork Dashboard README](https://github.com/patchwork-hub/patchwork_dashboard/blob/main/README.md).

## Features

### 🛡️ Spam & Moderation Filters
- Block posts containing specific hashtags
- Filter content based on keywords
- Customizable filtering rules for different timeline types
- Bulk filtering operations

### 🌐 Federation Controls
- Block or unblock Threads posts from appearing in timelines
- Control Bluesky post visibility
- Manage cross-platform content integration
- Fine-grained federation settings

### 📊 Management Interface
- Easy-to-use web interface through Patchwork Dashboard
- Real-time filter status updates
- Comprehensive logging and monitoring
- User-friendly configuration options

## Installation

1. Add this line to your Mastodon application's Gemfile:

```ruby
gem "content_filters", git: "https://github.com/patchwork-hub/content_filters"
```

2. Install the gem:
```bash
bundle install
```

3. Run the installation generator:
```bash
rails generate content_filters:install
```

4. Run database migrations:
```bash
rails db:migrate
```

5. Restart your Mastodon application:
```bash
systemctl restart mastodon-web
systemctl restart mastodon-sidekiq
```

## Configuration

After installation, configure the plugin through the Patchwork Dashboard:

1. Navigate to your Patchwork Dashboard
2. Go to **Plugins** → **Content Filters**
3. Configure your filtering preferences
4. Save and apply changes

## Usage

### Setting up Keyword Filters
1. Access the Content Filters section in your dashboard
2. Add keywords or phrases to block
3. Choose which timelines to apply filters to
4. Set filter sensitivity levels

### Managing Federation Controls
1. Navigate to Federation Controls
2. Enable/disable Threads integration
3. Configure Bluesky post visibility
4. Set federation policies

## Development

To contribute to this gem:

```bash
git clone https://github.com/patchwork-hub/content_filters.git
cd content_filters
bundle install
bundle exec rspec  # Run tests
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

## License

This gem is available as open source under the [AGPL-3.0 License](AGPL-LICENSE).

## About Patchwork

Patchwork is an open-source project aimed at enhancing Mastodon servers with additional functionality and improved user experience. Learn more at [joinpatchwork.org](https://www.joinpatchwork.org/).
