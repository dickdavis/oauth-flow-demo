# frozen_string_literal: true

module OAuth
  ##
  # Base OAuth controller.
  class BaseController < ApplicationController
    rescue_from OAuth::ClientMismatchError do
      render plain: 'HTTP Basic: Access denied.', status: :unauthorized
    end

    rescue_from OAuth::InvalidRedirectUrlError, OAuth::InvalidClientError do |error|
      render_client_error(error_class: error.class, error_message: error.message)
    end

    private

    def authenticate_client(id: nil)
      client_id = id || params[:client_id]
      load_oauth_client(id: client_id)
      return if @oauth_client.present? && @oauth_client.public_client_type?
      return if http_basic_auth_successful?

      request_http_basic_authentication
    end

    def load_oauth_client(id: nil)
      @oauth_client = OAuth::Client.find_by(id:)
    end

    def http_basic_auth_successful?
      authenticate_with_http_basic do |id, api_key|
        @oauth_client = OAuth::Client.find_by(id:)
        raise OAuth::ClientMismatchError if params.key?(:client_id) && params[:client_id] != @oauth_client.id

        api_key == @oauth_client.api_key
      end
    end

    def render_client_error(error_class:, error_message:)
      render 'oauth/client_error', status: :bad_request, locals: { error_class:, error_message: }
    end
  end
end
