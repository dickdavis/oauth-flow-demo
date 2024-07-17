# frozen_string_literal: true

module OAuth
  ##
  # Provides support for validating token claims
  module SessionCreatable
    extend ActiveSupport::Concern

    TokenContainer = Data.define(:access_token, :refresh_token, :expiration)

    private

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_oauth_session(grant:)
      oauth_client = grant.oauth_client
      access_token_expiration = oauth_client.access_token_duration.seconds.from_now.to_i
      access_token = OAuth::AccessToken.default(user_id:, exp: access_token_expiration)

      refresh_token_expiration = oauth_client.refresh_token_duration.seconds.from_now.to_i
      refresh_token = OAuth::RefreshToken.default(exp: refresh_token_expiration)

      oauth_session = grant.oauth_sessions.new(
        access_token_jti: access_token.jti, refresh_token_jti: refresh_token.jti
      )

      if oauth_session.save
        yield
        TokenContainer[access_token.to_encoded_token, refresh_token.to_encoded_token, access_token.exp]
      else
        errors = oauth_session.errors.full_messages.join(', ')
        raise OAuth::ServerError, I18n.t('oauth.errors.oauth_session_failure', errors:)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
