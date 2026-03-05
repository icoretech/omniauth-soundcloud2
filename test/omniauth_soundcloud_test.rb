# frozen_string_literal: true

require_relative 'test_helper'

require 'uri'

class OmniauthSoundcloudTest < Minitest::Test
  def build_strategy
    OmniAuth::Strategies::SoundCloud.new(nil, 'client-id', 'client-secret')
  end

  def test_uses_current_soundcloud_endpoints
    client_options = build_strategy.options.client_options

    assert_equal 'https://api.soundcloud.com', client_options.site
    assert_equal 'https://secure.soundcloud.com/authorize', client_options.authorize_url
    assert_equal 'https://secure.soundcloud.com/oauth/token', client_options.token_url
    assert_equal :request_body, client_options.auth_scheme
  end

  def test_default_scope_is_non_expiring
    strategy = build_strategy

    assert_equal 'non-expiring', strategy.options.scope
  end

  def test_uid_info_and_extra_are_derived_from_raw_info
    strategy = build_strategy
    payload = {
      'id' => 12_345_678,
      'username' => 'Sample User',
      'full_name' => 'Sample User',
      'avatar_url' => 'https://example.test/avatar-large.jpg',
      'description' => nil,
      'city' => nil,
      'website' => nil,
      'permalink_url' => 'https://soundcloud.com/sample-user?utm_source=id_123'
    }

    strategy.instance_variable_set(:@raw_info, payload)

    assert_equal '12345678', strategy.uid
    assert_equal(
      {
        name: 'Sample User',
        nickname: 'Sample User',
        image: 'https://example.test/avatar-large.jpg',
        urls: {
          SoundCloud: 'https://soundcloud.com/sample-user?utm_source=id_123'
        }
      },
      strategy.info
    )
    assert_equal({ 'raw_info' => payload }, strategy.extra)
  end

  def test_info_handles_sparse_payload_without_optional_fields
    strategy = build_strategy
    payload = {
      'id' => 12_345_678,
      'username' => 'sample-user',
      'full_name' => 'Soundcloud User',
      'description' => ''
    }

    strategy.instance_variable_set(:@raw_info, payload)

    assert_equal(
      {
        name: 'Soundcloud User',
        nickname: 'sample-user'
      },
      strategy.info
    )
  end

  def test_credentials_include_refresh_token_and_expiry_metadata
    strategy = build_strategy
    token = FakeCredentialAccessToken.new(
      token: 'access-token',
      refresh_token: 'refresh-token',
      expires_at: 1_772_691_847,
      expires: true,
      params: {}
    )

    strategy.define_singleton_method(:access_token) { token }

    assert_equal(
      {
        'token' => 'access-token',
        'refresh_token' => 'refresh-token',
        'expires_at' => 1_772_691_847,
        'expires' => true
      },
      strategy.credentials
    )
  end

  def test_credentials_include_refresh_token_when_token_is_non_expiring
    strategy = build_strategy
    token = FakeCredentialAccessToken.new(
      token: 'access-token',
      refresh_token: 'refresh-token',
      expires_at: nil,
      expires: false,
      params: { 'scope' => 'non-expiring' }
    )

    strategy.define_singleton_method(:access_token) { token }

    assert_equal(
      {
        'token' => 'access-token',
        'refresh_token' => 'refresh-token',
        'expires' => false,
        'scope' => 'non-expiring'
      },
      strategy.credentials
    )
  end

  def test_raw_info_calls_me_endpoint_and_memoizes
    strategy = build_strategy
    token = FakeAccessToken.new({ 'id' => 12_345_678 })

    strategy.define_singleton_method(:access_token) { token }

    first_call = strategy.raw_info
    second_call = strategy.raw_info

    assert_equal({ 'id' => 12_345_678 }, first_call)
    assert_same first_call, second_call
    assert_equal 1, token.calls.length
    assert_equal 'me', token.calls.first[:path]
  end

  def test_callback_url_prefers_configured_value
    strategy = build_strategy
    callback = 'https://example.test/auth/soundcloud/callback'
    strategy.options[:callback_url] = callback

    assert_equal callback, strategy.callback_url
  end

  def test_request_phase_redirects_to_soundcloud_with_expected_params
    previous_request_validation_phase = OmniAuth.config.request_validation_phase
    OmniAuth.config.request_validation_phase = nil

    app = ->(_env) { [404, { 'Content-Type' => 'text/plain' }, ['not found']] }
    strategy = OmniAuth::Strategies::SoundCloud.new(app, 'client-id', 'client-secret')
    env = Rack::MockRequest.env_for('/auth/soundcloud', method: 'POST')
    env['rack.session'] = {}

    status, headers, = strategy.call(env)

    assert_equal 302, status
    location = URI.parse(headers['Location'])
    params = URI.decode_www_form(location.query).to_h

    assert_equal 'secure.soundcloud.com', location.host
    assert_equal 'client-id', params.fetch('client_id')
  ensure
    OmniAuth.config.request_validation_phase = previous_request_validation_phase
  end

  def test_query_string_is_ignored_during_callback_request
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/soundcloud/callback?code=abc&state=xyz'))
    strategy.define_singleton_method(:request) { request }

    assert_equal '', strategy.query_string
  end

  def test_query_string_is_kept_for_non_callback_requests
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/soundcloud?display=popup'))
    strategy.define_singleton_method(:request) { request }

    assert_equal '?display=popup', strategy.query_string
  end

  def test_legacy_require_paths_and_constants_remain_supported
    require 'omniauth/soundcloud'
    require 'omniauth-soundcloud'
    require 'omniauth-soundcloud/version'

    assert_equal OmniAuth::Soundcloud2::VERSION, OmniAuth::SoundCloud::VERSION
    assert_equal OmniAuth::Soundcloud2::VERSION, OmniAuth::Soundcloud::VERSION
  end

  class FakeAccessToken
    attr_reader :calls

    def initialize(parsed_payload)
      @parsed_payload = parsed_payload
      @calls = []
    end

    def get(path)
      @calls << { path: path }
      Struct.new(:parsed).new(@parsed_payload)
    end
  end

  class FakeCredentialAccessToken
    attr_reader :token, :refresh_token, :expires_at, :params

    def initialize(token:, refresh_token:, expires_at:, expires:, params:)
      @token = token
      @refresh_token = refresh_token
      @expires_at = expires_at
      @expires = expires
      @params = params
    end

    def expires?
      @expires
    end

    def [](key)
      { 'scope' => @params['scope'] }[key]
    end
  end
end
