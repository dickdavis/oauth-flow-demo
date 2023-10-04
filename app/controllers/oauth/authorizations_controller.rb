# frozen_string_literal: true

module OAuth
  ##
  # Controller for authorizing an OAuth request.
  class AuthorizationsController < BaseController
    rescue_from OAuth::MissingClientIdError, OAuth::InvalidRedirectUrlError do |error|
      render_client_error(error_class: error.class, error_message: error.message)
    end

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
        redirect_to new_oauth_authorization_grant_path(state: body)
      when :invalid_request
        result = ClientRedirectUrlService.call(
          client_id:,
          params: { error: status, state: }.compact
        )
        redirect_to result.url, allow_other_host: true
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

    private

    def render_client_error(error_class:, error_message:)
      render 'oauth/client_error', status: :bad_request, locals: { error_class:, error_message: }
    end
  end
end
