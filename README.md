# OmniAuth SoundCloud2 Strategy

[![Test](https://github.com/icoretech/omniauth-soundcloud2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/icoretech/omniauth-soundcloud2/actions/workflows/test.yml?query=branch%3Amain)
[![Gem Version](https://img.shields.io/gem/v/omniauth-soundcloud2.svg)](https://rubygems.org/gems/omniauth-soundcloud2)

`omniauth-soundcloud2` provides a SoundCloud OAuth2 strategy for OmniAuth.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-soundcloud2'
```

Then run:

```bash
bundle install
```

## Usage

Configure OmniAuth in your Rack/Rails app:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :soundcloud,
           ENV.fetch('SOUNDCLOUD_CLIENT_ID'),
           ENV.fetch('SOUNDCLOUD_CLIENT_SECRET')
end
```

You can optionally pass `scope` and `display` in the request query.

## Auth Hash

Example payload from `request.env['omniauth.auth']` (realistic shape, anonymized):

```json
{
  "uid": "12345678",
  "info": {
    "name": "Soundcloud User",
    "nickname": "soundclouder",
    "image": "https://i1.sndcdn.com/avatars-example-large.jpg",
    "location": "Berlin",
    "urls": {
      "SoundCloud": "https://soundcloud.com/soundclouder",
      "Website": "https://example.test"
    }
  },
  "credentials": {
    "token": "sample-access-token",
    "expires_at": 1710000000,
    "expires": true
  },
  "extra": {
    "raw_info": {
      "id": 12345678,
      "username": "soundclouder",
      "full_name": "Soundcloud User",
      "avatar_url": "https://i1.sndcdn.com/avatars-example-large.jpg",
      "city": "Berlin",
      "website": "https://example.test",
      "permalink_url": "https://soundcloud.com/soundclouder"
    }
  }
}
```

## Development

```bash
bundle install
bundle exec rake
```

Run Rails integration tests with an explicit Rails version:

```bash
RAILS_VERSION='~> 8.1.0' bundle install
RAILS_VERSION='~> 8.1.0' bundle exec rake test_rails_integration
```

## Compatibility

- Ruby: `>= 3.2` (tested on `3.2`, `3.3`, `3.4`, `4.0`)
- `omniauth-oauth2`: `>= 1.8`, `< 1.9`
- Rails integration lanes: `~> 7.1.0`, `~> 7.2.0`, `~> 8.0.0`, `~> 8.1.0`

## Release

Tag releases as `vX.Y.Z`; GitHub Actions publishes the gem to RubyGems.

## License

MIT
