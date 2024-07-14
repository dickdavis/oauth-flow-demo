# frozen_string_literal: true

module OAuth
  ##
  # Controller for granting authorization to clients
  class AuthorizationGrantsController < BaseController
    before_action :authenticate_user
    before_action :set_authorization_request
    before_action :set_oauth_client

    def new
      state = @authorization_request.to_internal_state_token
      client_name = @oauth_client.name
      render :new, locals: { state:, client_name: }
    end

    # rubocop:disable Metrics/MethodLength
    def create
      state = @authorization_request.state

      unless ActiveModel::Type::Boolean.new.cast(params[:approve])
        redirect_to_client(params_for_redirect: { error: 'access_denied', state: }) and return
      end

      grant = @oauth_client.new_authorization_grant(
        user: current_user,
        challenge_params: {
          code_challenge: @authorization_request.code_challenge,
          code_challenge_method: @authorization_request.code_challenge_method,
          redirect_uri: @authorization_request.redirect_uri
        }
      )

      redirect_to_client(params_for_redirect: { code: grant.id, state: }) and return if grant.persisted?

      redirect_to_client(params_for_redirect: { error: 'invalid_request', state: })
    end
    # rubocop:enable Metrics/MethodLength

    private

    def set_authorization_request
      @authorization_request = OAuth::AuthorizationRequest.from_internal_state_token(params[:state])
    end

    def set_oauth_client
      @oauth_client = @authorization_request.oauth_client
    end

    def redirect_to_client(params_for_redirect:)
      url = @oauth_client.url_for_redirect(params: params_for_redirect.compact)
      redirect_to url, allow_other_host: true
    end
  end
end
