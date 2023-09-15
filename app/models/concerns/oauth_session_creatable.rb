# frozen_string_literal: true

##
# Provides support for validating token claims
module OAuthSessionCreatable
  extend ActiveSupport::Concern

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def create_oauth_session(authorization_grant:)
    access_token_expiration = oauth_config.access_token_expiration.minutes.from_now
    client_id = authorization_grant.client_id

    access_token_jti, access_token = OAuthTokenEncoderService.call(
      client_id:,
      expiration: access_token_expiration,
      optional_claims: { user_id: }
    ).deconstruct

    refresh_token_jti, refresh_token = OAuthTokenEncoderService.call(
      client_id:,
      expiration: oauth_config.refresh_token_expiration.minutes.from_now
    ).deconstruct

    oauth_session = authorization_grant.oauth_sessions.new(access_token_jti:, refresh_token_jti:)
    if oauth_session.save
      yield
      Data
        .define(:access_token, :refresh_token, :expiration)
        .new(access_token, refresh_token, access_token_expiration.to_i)
    else
      errors = oauth_session.errors.full_messages.join(', ')
      raise OAuth::ServerError, I18n.t('oauth.server_error.oauth_session_failure', errors:)
    end
  rescue OAuth::InvalidTokenParamError => error
    raise OAuth::ServerError, error.message
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def oauth_config
    @oauth_config ||= Rails.configuration.oauth
  end
end
