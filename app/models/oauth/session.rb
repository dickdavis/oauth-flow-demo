# frozen_string_literal: true

module OAuth
  ##
  # Models an oauth session with minimal data from session.
  class Session < ApplicationRecord
    include OAuth::SessionCreatable
    include OAuth::SessionExchangeable

    STATUS_ENUM_VALUES = {
      created: 'created',
      expired: 'expired',
      refreshed: 'refreshed',
      revoked: 'revoked'
    }.freeze

    VALID_UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}/i

    belongs_to :oauth_authorization_grant, class_name: 'OAuth::AuthorizationGrant'

    enum status: STATUS_ENUM_VALUES, _suffix: true

    delegate :user_id, to: :oauth_authorization_grant

    validates :access_token_jti, presence: true, uniqueness: true, format: { with: VALID_UUID_REGEX }
    encrypts :access_token_jti, deterministic: true

    validates :refresh_token_jti, presence: true, uniqueness: true, format: { with: VALID_UUID_REGEX }
    encrypts :refresh_token_jti, deterministic: true

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def refresh(token:, client_id:)
      raise OAuth::ServerError, I18n.t('oauth.errors.mismatched_refresh_token') unless token.jti == refresh_token_jti
      raise OAuth::InvalidGrantError unless token.valid?

      # Detect stolen refresh token and replay attacks, and then revoke current active oauth session
      unless created_status? && client_id == oauth_authorization_grant.oauth_client.id
        session = oauth_authorization_grant.active_oauth_session || self
        session.update(status: 'revoked')
        raise OAuth::RevokedSessionError.new(
          client_id:,
          refreshed_session_id: id,
          revoked_session_id: session.id,
          user_id:
        )
      end

      create_oauth_session(grant: oauth_authorization_grant) do
        update(status: 'refreshed')
      end
    rescue OAuth::ServerError => error
      raise OAuth::ServerError, error.message
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def revoke_self_and_active_session
      ActiveRecord::Base.transaction do
        update(status: 'revoked')
        oauth_authorization_grant.active_oauth_session&.update(status: 'revoked')
      end
    end

    def self.revoke_for_token(jti:)
      # Must use find_by in this manner due to AR encryption
      oauth_session = find_by(access_token_jti: jti) || find_by(refresh_token_jti: jti)
      execute_revocation(oauth_session:)
    end

    def self.revoke_for_access_token(access_token_jti:)
      oauth_session = find_by(access_token_jti:)
      execute_revocation(oauth_session:)
    end

    def self.revoke_for_refresh_token(refresh_token_jti:)
      oauth_session = find_by(refresh_token_jti:)
      execute_revocation(oauth_session:)
    end

    class << self
      def execute_revocation(oauth_session:)
        return if oauth_session.blank?

        oauth_session.revoke_self_and_active_session
      end
    end
  end
end
