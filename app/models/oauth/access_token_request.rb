# frozen_string_literal: true

module OAuth
  ##
  # Models a access token request
  class AccessTokenRequest
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :code_verifier, :oauth_authorization_grant, :redirect_uri

    validate :oauth_authorization_grant_must_be_valid
    validate :code_verifier_must_be_valid
    validate :redirect_uri_must_be_valid

    private

    def oauth_authorization_grant_must_be_valid
      errors.add(:oauth_authorization_grant, :invalid) and return unless oauth_authorization_grant_present?

      errors.add(:oauth_authorization_grant, :redeemed) if oauth_authorization_grant.redeemed?
    end

    def code_verifier_must_be_valid
      return unless oauth_authorization_grant_present?

      if oauth_client.public_client_type?
        validate_code_verifier_for_public
      else
        validate_code_verifier_for_confidential
      end
    end

    def validate_code_verifier_for_public
      errors.add(:code_verifier, :blank) and return if code_verifier.blank?

      validate_code_verifier_matches_code_challenge
    end

    def validate_code_verifier_for_confidential
      return unless challenge_required?

      if code_verifier.blank? && challenge_params_present_in_authorize?
        errors.add(:code_verifier, :present_in_authorize) and return
      end

      validate_code_verifier_matches_code_challenge
    end

    def challenge_required?
      code_verifier.present? || challenge_params_present_in_authorize?
    end

    def challenge_params_present_in_authorize?
      oauth_challenge.code_challenge.present? || oauth_challenge.code_challenge_method.present?
    end

    def validate_code_verifier_matches_code_challenge
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
      errors.add(:code_verifier, :does_not_validate_code_challenge) unless oauth_challenge.code_challenge == challenge
    end

    def redirect_uri_must_be_valid
      return unless oauth_authorization_grant_present?

      if oauth_client.public_client_type?
        validate_redirect_uri_for_public
      else
        validate_redirect_uri_for_confidential
      end
    end

    def validate_redirect_uri_for_public
      errors.add(:redirect_uri, :blank) and return if redirect_uri.blank?

      validate_redirect_uri_matches_authorize_param
    end

    def validate_redirect_uri_for_confidential
      return unless redirect_uri.present? || redirect_uri_param_present_in_authorize?

      errors.add(:redirect_uri, :present_in_authorize) and return if redirect_uri.blank?

      validate_redirect_uri_matches_authorize_param
    end

    def validate_redirect_uri_matches_authorize_param
      errors.add(:redirect_uri, :mismatched) unless oauth_challenge.redirect_uri == redirect_uri
    end

    def redirect_uri_param_present_in_authorize?
      oauth_challenge.redirect_uri.present?
    end

    def oauth_authorization_grant_present?
      return @oauth_authorization_grant_present if defined?(@oauth_authorization_grant_present)

      @oauth_authorization_grant_present = oauth_authorization_grant&.is_a?(OAuth::AuthorizationGrant)
    end

    def oauth_client
      @oauth_client ||= oauth_authorization_grant.oauth_client
    end

    def oauth_challenge
      @oauth_challenge ||= oauth_authorization_grant.oauth_challenge
    end
  end
end
