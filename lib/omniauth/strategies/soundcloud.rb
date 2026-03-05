# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    # OmniAuth strategy for SoundCloud OAuth2.
    class SoundCloud < OmniAuth::Strategies::OAuth2
      DEFAULT_SCOPE = 'non-expiring'

      option :name, 'soundcloud'

      option :client_options,
             site: 'https://api.soundcloud.com',
             authorize_url: 'https://secure.soundcloud.com/authorize',
             token_url: 'https://secure.soundcloud.com/oauth/token',
             auth_scheme: :request_body,
             connection_opts: {
               headers: {
                 user_agent: 'icoretech-omniauth-soundcloud2 gem',
                 accept: 'application/json',
                 content_type: 'application/json'
               }
             }

      option :authorize_options, %i[scope state display]
      option :scope, DEFAULT_SCOPE

      uid { raw_info['id'].to_s }

      info do
        {
          name: raw_info['full_name'] || raw_info['username'],
          nickname: raw_info['username'],
          image: raw_info['avatar_url'],
          description: blank_to_nil(raw_info['description']),
          location: raw_info['city'],
          urls: urls
        }.compact
      end

      credentials do
        {
          'token' => access_token.token,
          'refresh_token' => access_token.refresh_token,
          'expires_at' => access_token.expires_at,
          'expires' => access_token.expires?,
          'scope' => token_scope
        }.compact
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('me').parsed
      end

      # Ensure token exchange uses a stable callback URI that matches provider config.
      def callback_url
        options[:callback_url] || super
      end

      # Prevent authorization response params from being appended to redirect_uri.
      def query_string
        return '' if request.params['code']

        super
      end

      private

      def token_scope
        token_params = access_token.respond_to?(:params) ? access_token.params : {}
        token_params['scope'] || (access_token['scope'] if access_token.respond_to?(:[]))
      end

      def urls
        data = {
          SoundCloud: raw_info['permalink_url'],
          Website: raw_info['website']
        }.compact
        data.empty? ? nil : data
      end

      def blank_to_nil(value)
        return nil if value.respond_to?(:empty?) && value.empty?

        value
      end
    end

    Soundcloud = SoundCloud
    SoundCloud2 = SoundCloud
  end
end

OmniAuth.config.add_camelization 'soundcloud', 'SoundCloud'
