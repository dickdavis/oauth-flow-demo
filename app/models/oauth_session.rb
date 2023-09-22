# frozen_string_literal: true

##
# Models an oauth session with minimal data from session.
class OAuthSession < ApplicationRecord
  include OAuthSessionCreatable

  STATUS_ENUM_VALUES = {
    created: 'created',
    expired: 'expired',
    refreshed: 'refreshed',
    revoked: 'revoked'
  }.freeze

  VALID_UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}/i

  delegate :user_id, to: :authorization_grant

  validates :access_token_jti, presence: true, uniqueness: true, format: { with: VALID_UUID_REGEX }
  encrypts :access_token_jti, deterministic: true

  validates :refresh_token_jti, presence: true, uniqueness: true, format: { with: VALID_UUID_REGEX }
  encrypts :refresh_token_jti, deterministic: true

  belongs_to :authorization_grant

  enum status: STATUS_ENUM_VALUES, _suffix: true

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def refresh(token:)
    raise OAuth::ServerError, I18n.t('oauth.mismatched_refresh_token_error') unless token.jti == refresh_token_jti
    raise OAuth::InvalidGrantError unless token.valid?

    # Detect refresh token replay attacks and revoke current active oauth session
    unless created_status?
      session = authorization_grant.active_oauth_session || self
      session.update(status: 'revoked')
      raise OAuth::RevokedSessionError.new(
        client_id: authorization_grant.client_id,
        refreshed_session_id: id,
        revoked_session_id: session.id,
        user_id:
      )
    end

    create_oauth_session(authorization_grant:) do
      update(status: 'refreshed')
    end
  rescue OAuth::ServerError => error
    raise OAuth::ServerError, error.message
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
