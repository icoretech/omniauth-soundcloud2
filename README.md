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

## Provider App Setup

- SoundCloud apps: <https://soundcloud.com/you/apps>
- OAuth guide: <https://developers.soundcloud.com/docs/api/guide#authentication>
- Register callback URL (example): `https://your-app.example.com/auth/soundcloud/callback`

## Options

- `scope` (default: `non-expiring`)
- `display`

## Auth Hash

Example payload from `request.env['omniauth.auth']` (realistic shape, anonymized):

```json
{
  "uid": "14743149",
  "info": {
    "name": "Sample Person",
    "nickname": "Sample Person",
    "image": "https://i1.sndcdn.com/avatars-000000000000-example-large.jpg",
    "urls": {
      "SoundCloud": "https://soundcloud.com/sample-person?utm_source=id_12345"
    }
  },
  "credentials": {
    "token": "eyJ...redacted...xYxvrQ",
    "refresh_token": "A1B2C3D4E5F6",
    "expires_at": 1772691847,
    "expires": true,
    "scope": "non-expiring"
  },
  "extra": {
    "raw_info": {
      "avatar_url": "https://i1.sndcdn.com/avatars-000000000000-example-large.jpg",
      "id": 14743149,
      "urn": "soundcloud:users:14743149",
      "kind": "user",
      "permalink_url": "https://soundcloud.com/sample-person?utm_source=id_12345",
      "uri": "https://api.soundcloud.com/users/soundcloud:users:14743149",
      "username": "Sample Person",
      "permalink": "sample-person",
      "created_at": "2012/04/05 16:38:45 +0000",
      "last_modified": "2016/12/07 19:35:32 +0000",
      "first_name": "Sample",
      "last_name": "Person",
      "full_name": "Sample Person",
      "city": null,
      "description": null,
      "country": null,
      "track_count": 1,
      "public_favorites_count": 0,
      "reposts_count": 0,
      "followers_count": 8,
      "followings_count": 1,
      "plan": "Free",
      "website_title": null,
      "website": null,
      "comments_count": 0,
      "online": false,
      "likes_count": 0,
      "playlist_count": 0,
      "subscriptions": [
        {
          "product": {
            "id": "free",
            "name": "Free"
          }
        }
      ],
      "quota": {
        "unlimited_upload_quota": false,
        "upload_seconds_used": 336,
        "upload_seconds_left": 10464
      },
      "private_tracks_count": 5,
      "private_playlists_count": 1,
      "primary_email_confirmed": true,
      "locale": "",
      "upload_seconds_left": 10464
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

## Test Structure

- `test/omniauth_soundcloud_test.rb`: strategy/unit behavior
- `test/rails_integration_test.rb`: full Rack/Rails request+callback flow
- `test/test_helper.rb`: shared test bootstrap

## Compatibility

- Ruby: `>= 3.2` (tested on `3.2`, `3.3`, `3.4`, `4.0`)
- `omniauth-oauth2`: `>= 1.8`, `< 1.9`
- Rails integration lanes: `~> 7.1.0`, `~> 7.2.0`, `~> 8.0.0`, `~> 8.1.0`

## Release

Tag releases as `vX.Y.Z`; GitHub Actions publishes the gem to RubyGems.

## License

MIT
