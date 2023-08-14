# frozen_string_literal: true

require 'jwt'

##
# Module for encoding and decoding JWTs.
module JsonWebToken
  def self.encode(payload, expiration = 30.minutes.from_now)
    payload[:exp] = expiration.to_i
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode(token)
    decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
    ActiveSupport::HashWithIndifferentAccess.new(decoded_token)
  end
end
