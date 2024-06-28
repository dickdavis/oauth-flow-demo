# frozen_string_literal: true

module OAuth
  ##
  # Controller for issuing access and refresh tokens.
  class SessionsController < BaseController
    skip_before_action :verify_authenticity_token

    rescue_from OAuth::InvalidGrantError do
      render_token_request_error(error: 'invalid_grant')
    end

    rescue_from OAuth::ServerError do |error|
      Rails.logger.error(error.message)
      render_token_request_error(error: 'server_error', status: :internal_server_error)
    end

    def token
      authorization_grant = AuthorizationGrant.find_by(id: params[:code])
      raise OAuth::InvalidGrantError if authorization_grant.blank? || authorization_grant.redeemed?

      access_token, refresh_token, expiration = authorization_grant.redeem(
        code_verifier: params[:code_verifier]
      ).deconstruct

      render json: { access_token:, refresh_token:, token_type: 'bearer', expires_in: expiration }
    rescue OAuth::InvalidCodeVerifierError
      render_token_request_error(error: 'invalid_request')
    end

    def refresh
      token = RefreshToken.new(JsonWebToken.decode(params[:refresh_token]))
      oauth_session = OAuthSession.find_by(refresh_token_jti: token.jti)

      access_token, refresh_token, expiration = oauth_session.refresh(token:).deconstruct

      render json: { access_token:, refresh_token:, token_type: 'bearer', expires_in: expiration }
    rescue JWT::DecodeError
      render_token_request_error(error: 'invalid_request')
    rescue OAuth::RevokedSessionError => error
      Rails.logger.warn(error.message)
      render_token_request_error(error: 'invalid_request')
    end

    def exchange
      head :ok
    end

    def unsupported_grant_type
      render_token_request_error(error: 'unsupported_grant_type')
    end

    def revoke
      token = JsonWebToken.decode(params[:token])
      OAuthSession.revoke_for_token(jti: token[:jti])

      head :ok
    rescue JWT::DecodeError
      render_unsupported_token_type_error
    end

    def revoke_access_token
      token = AccessToken.new(JsonWebToken.decode(params[:token]))
      OAuthSession.revoke_for_access_token(access_token_jti: token.jti)

      head :ok
    rescue JWT::DecodeError
      render_unsupported_token_type_error
    end

    def revoke_refresh_token
      token = RefreshToken.new(JsonWebToken.decode(params[:token]))
      OAuthSession.revoke_for_refresh_token(refresh_token_jti: token.jti)

      head :ok
    rescue JWT::DecodeError
      render_unsupported_token_type_error
    end

    private

    def render_token_request_error(error:, status: :bad_request)
      render json: { error: }, status:
    end

    def render_unsupported_token_type_error
      render json: { error: 'unsupported_token_type' }, status: :bad_request
    end
  end
end
