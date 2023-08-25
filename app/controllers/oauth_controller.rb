# frozen_string_literal: true

##
# Controller for OAuth flow.
class OAuthController < ApplicationController
  before_action :authenticate_client

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
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  private

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
end
