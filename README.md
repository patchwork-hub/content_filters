## Overview

Filter content on your Patchwork enhanced Mastodon server timelines.

To enable this plugin please make sure you have set up a Mastodon server and installed the Patchwork Dashboard, with both running correctly.

[See the full Patchwork ReadMe here.](https://github.com/patchwork-hub/patchwork_dashboard/blob/main/README.md)

### Features

#### Filters
Filter your timelines by blocking posts with defined hashtags and keywords.


#### Manage connection with Bluesky & Threads
Easily manage your timelines by blocking or unblocking Threads and Bluesky posts.

## Installation

Before installing this gem, please make sure that below systems are up and running:
- [Set up a Mastodon server](https://docs.joinmastodon.org/admin/install/)
- [Patchwork Dashboard](https://github.com/patchwork-hub/patchwork_dashboard/blob/main/README.md)

1. Add this line to your Mastodon application's Gemfile:

```ruby
gem "content_filters", git: "https://github.com/patchwork-hub/content_filters"
```

2. Execute to install the gem:
```bash
$ bundle install
```

3. After installing the gem, restart your application to load it in your application.

## License
The gem is available as open source under AGPL-3.0.
