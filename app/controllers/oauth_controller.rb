# frozen_string_literal: true

##
# Controller for OAuth flow.
class OAuthController < ApplicationController
  before_action :authenticate_client
  skip_before_action :verify_authenticity_token, only: :token

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def authorize
    client_id = params[:client_id]
    state = params[:state]
    raise OAuth::MissingClientIdError if client_id.blank?

    status, body = StateTokenEncoderService.call(
      client_id:,
      client_state: state,
      code_challenge: params[:code_challenge],
      code_challenge_method: params[:code_challenge_method],
      response_type: params[:response_type]
    ).deconstruct

    case status
    when :ok
      redirect_to new_authorization_grant_path(state: body)
    when :invalid_request
      result = ClientRedirectUrlService.call(
        client_id:,
        params: { error: status, state: }.compact
      )
      redirect_to result.url, allow_other_host: true
    end
  rescue OAuth::MissingClientIdError, OAuth::InvalidRedirectUrlError => error
    render 'oauth/client_error',
           status: :bad_request,
           locals: { error_class: error.class, message: error.message }
  end

  def token
    authorization_grant = AuthorizationGrant.find_by(id: params[:code])
    TokenRequestValidatorService.call!(
      authorization_grant:, code_verifier: params[:code_verifier], grant_type: params[:grant_type]
    )

    access_token, refresh_token, expiration = authorization_grant.create_oauth_session.deconstruct

    render json: { access_token:, refresh_token:, token_type: 'bearer', expires_in: expiration }
  rescue OAuth::UnsupportedGrantTypeError
    render_token_request_error(error: 'unsupported_grant_type')
  rescue OAuth::InvalidGrantError
    render_token_request_error(error: 'invalid_grant')
  rescue OAuth::InvalidRequestError
    render_token_request_error(error: 'invalid_request')
  rescue OAuth::ServerError => error
    Rails.logger.error(error.message)
    render_token_request_error(error: 'server_error', status: :internal_server_error)
  end

  private

  def oauth_config
    @oauth_config ||= Rails.configuration.oauth
  end

  def authenticate_client
    return if http_basic_auth_successful?

    request_http_basic_authentication
  end

  def http_basic_auth_successful?
    authenticate_with_http_basic do |id, secret|
      return false if params.key?(:client_id) && params[:client_id] != id

      secret == Rails.application.credentials.clients[id.to_sym]
    end
  end

  def render_token_request_error(error:, status: :bad_request)
    render json: { error: }, status:
  end
end
