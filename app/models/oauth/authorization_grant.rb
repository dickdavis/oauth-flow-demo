# frozen_string_literal: true

module OAuth
  ##
  # Models an authorization grant.
  class AuthorizationGrant < ApplicationRecord
    include OAuth::SessionCreatable

    belongs_to :user
    belongs_to :oauth_client, class_name: 'OAuth::Client'
    has_many :oauth_sessions,
             class_name: 'OAuth::Session',
             foreign_key: :oauth_authorization_grant_id,
             inverse_of: :oauth_authorization_grant,
             dependent: :destroy
    has_one :oauth_challenge,
            class_name: 'OAuth::Challenge',
            foreign_key: :oauth_authorization_grant_id,
            inverse_of: :oauth_authorization_grant,
            dependent: :destroy

    accepts_nested_attributes_for :oauth_challenge

    before_validation :generate_expires_at

    def active_oauth_session
      oauth_sessions.created_status.order(created_at: :desc).first
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    def redeem(redirection_uri:, code_verifier: nil)
      raise OAuth::InvalidGrantError if redeemed?

      if oauth_client.public_client_type? || oauth_challenge.code_challenge.present?
        oauth_challenge.validate_code_challenge(code_verifier:)
      end

      if oauth_client.public_client_type? || oauth_challenge.redirect_uri.present?
        oauth_challenge.validate_redirect_uri(redirection_uri:)
      end

      if oauth_challenge.errors.any?
        raise OAuth::UnsuccessfulChallengeError, oauth_challenge.errors.full_messages.join(', ')
      end

      create_oauth_session(authorization_grant: self) do
        update(redeemed: true)
      end
    rescue OAuth::ServerError => error
      raise OAuth::ServerError, error.message
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

    private

    def generate_expires_at
      self.expires_at ||= 5.minutes.from_now
    end
  end
end
