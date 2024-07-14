# frozen_string_literal: true

module OAuth
  ##
  # Controller for authorizing an OAuth request.
  class AuthorizationsController < BaseController
    before_action :authenticate_client

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def authorize
      state = params[:state]

      authorization_request = @oauth_client.new_authorization_request(
        client_id: params[:client_id],
        code_challenge: params[:code_challenge],
        code_challenge_method: params[:code_challenge_method],
        redirect_uri: params[:redirect_uri],
        response_type: params[:response_type],
        state:
      )

      if authorization_request.valid?
        redirect_to new_oauth_authorization_grant_path(state: authorization_request.to_internal_state_token)
      elsif authorization_request.errors.where(:redirect_uri).any?
        head :bad_request and return
      else
        params_for_redirect = { error: :invalid_request, state: }.compact
        url = @oauth_client.url_for_redirect(params: params_for_redirect.compact)
        redirect_to url, allow_other_host: true
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
