# frozen_string_literal: true

##
# Service which validates a token request
class TokenRequestValidatorService < ApplicationService
  def initialize(authorization_grant:, code_verifier:, grant_type:)
    super()
    @authorization_grant = authorization_grant
    @code_verifier = code_verifier
    @grant_type = grant_type
  end

  def call
    call!
  rescue OAuth::UnsupportedGrantTypeError, OAuth::InvalidGrantError, OAuth::InvalidRequestError
    false
  end

  def call!
    raise OAuth::UnsupportedGrantTypeError if invalid_grant_type?
    raise OAuth::InvalidGrantError if invalid_authorization_grant?
    raise OAuth::InvalidRequestError if invalid_code_verifier?

    true
  end

  private

  attr_reader :authorization_grant, :code_verifier, :grant_type

  def invalid_grant_type?
    grant_type != 'authorization_code'
  end

  def invalid_authorization_grant?
    authorization_grant.blank? || authorization_grant.redeemed?
  end

  def invalid_code_verifier?
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
    authorization_grant.code_challenge != challenge
  end
end
