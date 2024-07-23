# frozen_string_literal: true

module OAuth
  ##
  # Controller for issuing access and refresh tokens.
  class SessionsController < BaseController
    skip_before_action :verify_authenticity_token
    before_action :set_authorization_grant, only: :token
    before_action :authenticate_client, except: :unsupported_grant_type

    rescue_from OAuth::InvalidGrantError do
      render_token_request_error(error: 'invalid_grant')
    end

    rescue_from OAuth::ServerError do |error|
      Rails.logger.error(error.message)
      render_token_request_error(error: 'server_error', status: :internal_server_error)
    end

    # rubocop:disable Metrics/MethodLength
    def token
      access_token_request = OAuth::AccessTokenRequest.new(
        oauth_authorization_grant: @authorization_grant,
        code_verifier: params[:code_verifier],
        redirect_uri: params[:redirect_uri]
      )

      if access_token_request.valid?
        access_token, refresh_token, expiration = @authorization_grant.redeem.deconstruct
        render json: { access_token:, refresh_token:, token_type: 'bearer', expires_in: expiration }
      else
        render_token_request_error(error: 'invalid_request')
      end
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize
    def refresh
      token = OAuth::RefreshToken.from_token(params[:refresh_token])
      oauth_session = OAuth::Session.find_by(refresh_token_jti: token.jti)
      client_id = params[:client_id].presence || oauth_session.oauth_authorization_grant.oauth_client.id

      access_token, refresh_token, expiration = oauth_session.refresh(token:, client_id:).deconstruct

      render json: { access_token:, refresh_token:, token_type: 'bearer', expires_in: expiration }
    rescue JWT::DecodeError
      render_token_request_error(error: 'invalid_request')
    rescue OAuth::RevokedSessionError => error
      Rails.logger.warn(error.message)
      render_token_request_error(error: 'invalid_request')
    end
    # rubocop:enable Metrics/AbcSize

    def exchange
      oauth_session = oauth_session_from_subject_token
      resource = params[:resource]
      subject_token_type = params[:subject_token_type]
      oauth_session.validate_params_for_exchange!(resource:, subject_token_type:)

      render json: { resource:, subject_token_type: }
    rescue OAuth::InvalidResourceError, OAuth::InvalidSubjectTokenTypeError
      render_token_request_error(error: 'invalid_request')
    end

    def unsupported_grant_type
      render_token_request_error(error: 'unsupported_grant_type')
    end

    def revoke
      token = JsonWebToken.decode(params[:token])
      OAuth::Session.revoke_for_token(jti: token[:jti])

      head :ok
    rescue JWT::DecodeError
      render_unsupported_token_type_error
    end

    def revoke_access_token
      token = OAuth::AccessToken.from_token(params[:token])
      OAuth::Session.revoke_for_access_token(access_token_jti: token.jti)

      head :ok
    rescue JWT::DecodeError
      render_unsupported_token_type_error
    end

    def revoke_refresh_token
      token = OAuth::RefreshToken.from_token(params[:token])
      OAuth::Session.revoke_for_refresh_token(refresh_token_jti: token.jti)

      head :ok
    rescue JWT::DecodeError
      render_unsupported_token_type_error
    end

    private

    def set_authorization_grant
      @authorization_grant = OAuth::AuthorizationGrant.find_by(id: params[:code])
      raise OAuth::InvalidGrantError if @authorization_grant.blank? || @authorization_grant.redeemed?
    end

    def render_token_request_error(error:, status: :bad_request)
      render json: { error: }, status:
    end

    def render_unsupported_token_type_error
      render json: { error: 'unsupported_token_type' }, status: :bad_request
    end

    def oauth_session_from_subject_token
      access_token = OAuth::AccessToken.from_token(params[:subject_token])
      raise OAuth::UnauthorizedAccessTokenError unless access_token.valid?

      OAuth::Session.find_by!(access_token_jti: access_token.jti)
    rescue JWT::DecodeError
      raise OAuth::InvalidAccessTokenError
    rescue ActiveRecord::RecordNotFound
      raise OAuth::OAuthSessionNotFound
    end
  end
end
