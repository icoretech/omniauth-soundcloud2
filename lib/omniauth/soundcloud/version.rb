# frozen_string_literal: true

require "omniauth/soundcloud2/version"

module OmniAuth
  module SoundCloud
    VERSION = OmniAuth::Soundcloud2::VERSION unless const_defined?(:VERSION)
  end

  module Soundcloud
    VERSION = OmniAuth::Soundcloud2::VERSION unless const_defined?(:VERSION)
  end
end
