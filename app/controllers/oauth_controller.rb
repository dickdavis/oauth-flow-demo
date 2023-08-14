# frozen_string_literal: true

##
# Controller for OAuth flow.
class OAuthController < ApplicationController
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
end
