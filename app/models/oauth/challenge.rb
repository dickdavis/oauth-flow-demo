# frozen_string_literal: true

module OAuth
  ##
  # Models a challenge used in PKCE
  class Challenge < ApplicationRecord
    VALID_CODE_CHALLENGE_METHODS = %w[S256].freeze

    belongs_to :oauth_authorization_grant, class_name: 'OAuth::AuthorizationGrant'

    validates :code_challenge_method, allow_blank: true, inclusion: { in: VALID_CODE_CHALLENGE_METHODS }

    def validate_code_verifier!(code_verifier:)
      raise OAuth::InvalidCodeVerifierError unless valid_code_verifier?(code_verifier:)
    end

    def validate_redirection_uri!(redirection_uri:)
      raise OAuth::InvalidRedirectionURIError unless valid_redirection_uri?(redirection_uri:)
    end

    private

    def valid_code_verifier?(code_verifier:)
      return false if code_verifier.blank?

      challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
      code_challenge == challenge
    end

    def valid_redirection_uri?(redirection_uri:)
      redirection_uri == client_redirection_uri
    end
  end
end
