# frozen_string_literal: true

require 'oauth'

##
# Controller for OAuth flow.
class OAuthController < ApplicationController
  before_action :authenticate_client

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def authorize
    client_id = params[:client_id]
    raise OAuth::MissingClientIdError if client_id.blank?

    status, body = StateTokenEncoderService.call(
      client_id:,
      client_state: params[:state],
      code_challenge: params[:code_challenge],
      code_challenge_method: params[:code_challenge_method],
      response_type: params[:response_type]
    ).deconstruct

    case status
    when :ok
      redirect_to sign_in_path(state: body)
    when :bad_request
      render json: body, status:
    end
  rescue OAuth::MissingClientIdError => error
    render 'oauth/client_error', status: :bad_request, locals: { message: error.message }
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
