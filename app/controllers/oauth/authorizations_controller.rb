# frozen_string_literal: true

module OAuth
  ##
  # Controller for authorizing an OAuth request.
  class AuthorizationsController < BaseController
    before_action :authenticate_client

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def authorize
      state = params[:state]

      status, body = StateTokenEncoderService.call(
        client_id: @oauth_client.id,
        client_state: state,
        code_challenge: params[:code_challenge],
        code_challenge_method: params[:code_challenge_method],
        response_type: params[:response_type]
      ).deconstruct

      case status
      when :ok
        redirect_to new_oauth_authorization_grant_path(state: body)
      when :invalid_request
        params_for_redirect = { error: status, state: }.compact
        url = @oauth_client.url_for_redirect(params: params_for_redirect.compact)
        redirect_to url, allow_other_host: true
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
