# frozen_string_literal: true

module OAuth
  ##
  # Models a challenge used in PKCE
  class Challenge < ApplicationRecord
    VALID_CODE_CHALLENGE_METHODS = %w[S256].freeze

    belongs_to :oauth_authorization_grant, class_name: 'OAuth::AuthorizationGrant'

    validates :code_challenge_method, allow_blank: true, inclusion: { in: VALID_CODE_CHALLENGE_METHODS }

    def validate_code_challenge(code_verifier:)
      errors.add(:code_challenge, :requires_code_verifier) and return if code_verifier.blank?

      errors.add(:code_challenge, :failed_challenge) unless valid_code_verifier?(code_verifier:)
    end

    def validate_redirect_uri(redirection_uri:)
      errors.add(:redirect_uri, :invalid) unless valid_redirection_uri?(redirection_uri:)
    end

    private

    def valid_code_verifier?(code_verifier:)
      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
      code_challenge == challenge
    end

    def valid_redirection_uri?(redirection_uri:)
      redirection_uri == redirect_uri
    end
  end
end
