# frozen_string_literal: true

require 'omniauth/soundcloud2/version'

# Backward compatibility for historical constant usage.
module Omniauth
  module Soundcloud2
    VERSION = OmniAuth::Soundcloud2::VERSION unless const_defined?(:VERSION)
  end

  module SoundCloud
    VERSION = OmniAuth::Soundcloud2::VERSION unless const_defined?(:VERSION)
  end
end
