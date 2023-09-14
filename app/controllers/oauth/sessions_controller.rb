# frozen_string_literal: true

module OAuth
  ##
  # Controller for issuing access and refresh tokens.
  class SessionsController < BaseController
    skip_before_action :verify_authenticity_token

    rescue_from OAuth::UnsupportedGrantTypeError do
      render_token_request_error(error: 'unsupported_grant_type')
    end

    rescue_from OAuth::InvalidGrantError do
      render_token_request_error(error: 'invalid_grant')
    end

    rescue_from OAuth::InvalidTokenRequestError do
      render_token_request_error(error: 'invalid_request')
    end

    rescue_from OAuth::ServerError do |error|
      Rails.logger.error(error.message)
      render_token_request_error(error: 'server_error', status: :internal_server_error)
    end

    def token
      authorization_grant = AuthorizationGrant.find_by(id: params[:code])
      TokenRequestValidatorService.call!(
        authorization_grant:, code_verifier: params[:code_verifier], grant_type: params[:grant_type]
      )

      access_token, refresh_token, expiration = authorization_grant.create_oauth_session.deconstruct

      render json: { access_token:, refresh_token:, token_type: 'bearer', expires_in: expiration }
    end

    private

    def render_token_request_error(error:, status: :bad_request)
      render json: { error: }, status:
    end
  end
end
