# frozen_string_literal: true

module API
  ##
  # Base API controller.
  class BaseController < ActionController::API
    rescue_from OAuth::MissingAuthorizationHeaderError, with: :missing_auth_header_response
    rescue_from OAuth::InvalidAccessTokenError, with: :invalid_token_response
    rescue_from OAuth::UnauthorizedAccessTokenError, with: :unauthorized_token_response

    private

    # rubocop:disable Metrics/AbcSize
    def user_from_token
      bearer_token_header = request.headers['AUTHORIZATION']
      raise OAuth::MissingAuthorizationHeaderError if bearer_token_header.blank?

      token = bearer_token_header.split.last
      access_token = OAuth::AccessToken.from_token(token)
      raise OAuth::UnauthorizedAccessTokenError unless access_token.valid?

      oauth_session = OAuth::Session.find_by(access_token_jti: access_token.jti)
      raise OAuth::UnauthorizedAccessTokenError unless oauth_session.created_status?

      User.find(access_token.user_id)
    rescue JWT::DecodeError, ActiveModel::UnknownAttributeError
      raise OAuth::InvalidAccessTokenError
    end
    # rubocop:enable Metrics/AbcSize

    def missing_auth_header_response
      error_response(I18n.t('api.errors.missing_auth_header_response'))
    end

    def invalid_token_response
      error_response(I18n.t('api.errors.invalid_token_response'))
    end

    def unauthorized_token_response
      error_response(I18n.t('api.errors.unauthorized_token_response'))
    end

    def error_response(error)
      render json: { error: }, status: :unauthorized
    end
  end
end
