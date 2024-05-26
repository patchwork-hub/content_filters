## A Ruby on Rails plugin for filtering content on Mastodon timelines

## Features

### Filter contents on timelines by hashtags and keywords
Filter your timelines by blocking posts with defined hashtags and keywords.


### Filter Threads/Bluesky contents on timelines
Easily manage your timelines by blocking or unblocking Threads and Bluesky posts.

## Installation

Before installing this gem, please make sure that below systems are up and running:
- [A Mastodon server set up from source](https://docs.joinmastodon.org/admin/install/)
- [Patchwork dashboard system](https://github.com/patchwork-hub/patchwork_dashboard/blob/main/README.md)

Add this line to your Mastodon application's Gemfile:

```ruby
gem "content_filters", git: "https://github.com/patchwork-hub/content_filters"
```

And then execute to install the gem:
```bash
$ bundle install
```

After installing the gem, restart your application to load it in your application.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
