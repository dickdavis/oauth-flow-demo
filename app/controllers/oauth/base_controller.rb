# frozen_string_literal: true

module OAuth
  ##
  # Base OAuth controller.
  class BaseController < ApplicationController
    before_action :authenticate_client

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
  end
end
