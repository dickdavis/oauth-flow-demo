# frozen_string_literal: true

module OAuth
  ##
  # Provides support for validating token claims
  module SessionCreatable
    extend ActiveSupport::Concern

    TokenContainer = Data.define(:access_token, :refresh_token, :expiration)
    Token = Data.define(:jti, :token)

    private

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_oauth_session(authorization_grant:)
      oauth_client = authorization_grant.oauth_client
      access_token_expiration = oauth_client.access_token_duration.seconds.from_now
      refresh_token_expiration = oauth_client.refresh_token_duration.seconds.from_now

      access_token_jti, access_token = generate_token(
        expiration: access_token_expiration,
        optional_claims: { user_id: }
      ).deconstruct

      refresh_token_jti, refresh_token = generate_token(
        expiration: refresh_token_expiration
      ).deconstruct

      oauth_session = authorization_grant.oauth_sessions.new(access_token_jti:, refresh_token_jti:)
      if oauth_session.save
        yield
        TokenContainer[access_token, refresh_token, access_token_expiration.to_i]
      else
        errors = oauth_session.errors.full_messages.join(', ')
        raise OAuth::ServerError, I18n.t('oauth.server_error.oauth_session_failure', errors:)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def generate_token(expiration:, optional_claims: {})
      payload = {
        aud: OAuth::CONFIG.audience_url,
        iat: Time.zone.now.to_i,
        iss: OAuth::CONFIG.issuer_url,
        jti: SecureRandom.uuid
      }.merge(optional_claims)

      token = JsonWebToken.encode(payload, expiration)

      Token[payload[:jti], token]
    end
    # rubocop:enable Metrics/MethodLength
  end
end
