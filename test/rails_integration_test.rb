# frozen_string_literal: true

require_relative 'test_helper'

require 'action_controller/railtie'
require 'cgi'
require 'json'
require 'logger'
require 'rack/test'
require 'rails'
require 'uri'
require 'webmock/minitest'

class RailsIntegrationSessionsController < ActionController::Base
  def create
    auth = request.env.fetch('omniauth.auth')
    render json: {
      uid: auth['uid'],
      name: auth.dig('info', 'name') || auth.dig('info', 'nickname'),
      credentials: auth['credentials']
    }
  end

  def failure
    render json: { error: params[:message] }, status: :unauthorized
  end
end

class RailsIntegrationApp < Rails::Application
  config.root = File.expand_path('..', __dir__)
  config.eager_load = false
  config.secret_key_base = 'soundcloud2-rails-integration-test-secret-key'
  config.active_support.cache_format_version = 7.1 if config.active_support.respond_to?(:cache_format_version=)

  if config.active_support.respond_to?(:to_time_preserves_timezone=) &&
     Rails.gem_version < Gem::Version.new('8.1.0')
    config.active_support.to_time_preserves_timezone = :zone
  end
  config.hosts.clear
  config.hosts << 'example.org'
  config.logger = Logger.new(nil)

  config.middleware.use OmniAuth::Builder do
    provider :soundcloud, 'client-id', 'client-secret'
  end

  routes.append do
    match '/auth/:provider/callback', to: 'rails_integration_sessions#create', via: %i[get post]
    get '/auth/failure', to: 'rails_integration_sessions#failure'
  end
end

RailsIntegrationApp.initialize! unless RailsIntegrationApp.initialized?

class RailsIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    super
    @previous_test_mode = OmniAuth.config.test_mode
    @previous_allowed_request_methods = OmniAuth.config.allowed_request_methods
    @previous_request_validation_phase = OmniAuth.config.request_validation_phase

    OmniAuth.config.test_mode = false
    OmniAuth.config.allowed_request_methods = [:post]
    OmniAuth.config.request_validation_phase = nil
  end

  def teardown
    OmniAuth.config.test_mode = @previous_test_mode
    OmniAuth.config.allowed_request_methods = @previous_allowed_request_methods
    OmniAuth.config.request_validation_phase = @previous_request_validation_phase
    WebMock.reset!
    super
  end

  def app
    RailsIntegrationApp
  end

  def test_rails_request_and_callback_flow_returns_expected_auth_payload
    stub_soundcloud_token_exchange
    stub_soundcloud_me

    post '/auth/soundcloud'

    assert_equal 302, last_response.status

    authorize_uri = URI.parse(last_response['Location'])

    assert_equal 'secure.soundcloud.com', authorize_uri.host
    state = CGI.parse(authorize_uri.query).fetch('state').first

    get '/auth/soundcloud/callback', { code: 'oauth-test-code', state: state }

    assert_equal 200, last_response.status

    payload = JSON.parse(last_response.body)

    assert_equal '12345678', payload['uid']
    assert_equal 'Soundcloud User', payload['name']
    assert_equal 'access-token', payload.dig('credentials', 'token')
    assert_equal 'refresh-token', payload.dig('credentials', 'refresh_token')
    assert_equal 'non-expiring', payload.dig('credentials', 'scope')
    assert(payload.dig('credentials', 'expires'))

    assert_requested :post, 'https://secure.soundcloud.com/oauth/token', times: 1
    assert_requested :get, 'https://api.soundcloud.com/me', times: 1
  end

  private

  def stub_soundcloud_token_exchange
    stub_request(:post, 'https://secure.soundcloud.com/oauth/token').to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        access_token: 'access-token',
        refresh_token: 'refresh-token',
        scope: 'non-expiring',
        token_type: 'bearer',
        expires_in: 3600
      }.to_json
    )
  end

  def stub_soundcloud_me
    stub_request(:get, 'https://api.soundcloud.com/me').to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        id: 12_345_678,
        username: 'soundclouder',
        full_name: 'Soundcloud User',
        avatar_url: 'https://example.test/avatar.jpg',
        city: 'Berlin',
        permalink_url: 'https://soundcloud.com/soundclouder'
      }.to_json
    )
  end
end
