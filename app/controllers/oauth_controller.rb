# frozen_string_literal: true

##
# Controller for OAuth flow.
class OAuthController < ApplicationController
  before_action :authenticate_client

  # rubocop:disable Metrics/MethodLength
  def authorize
    status, body = StateTokenEncoderService.call(
      client_id: params[:client_id],
      client_state: params[:state],
      code_challenge: params[:code_challenge],
      code_challenge_method: params[:code_challenge_method],
      response_type: params[:response_type]
    ).deconstruct

    case status
    when :ok
      render 'oauth/authorize', locals: { state: body }
    when :bad_request
      render json: body, status:
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize
  def authenticate
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id.to_s
      redirect_to root_path
    else
      flash.now.alert = t('.login_failure')
      render 'oauth/authorize', locals: { state: params[:state] }
    end
  end
  # rubocop:enable Metrics/AbcSize

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
