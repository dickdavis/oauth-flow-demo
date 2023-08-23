# frozen_string_literal: true

##
# Service which returns a valid client redirect url with provided params
class ClientRedirectUrlService < ApplicationService
  Response = Data.define(:url)

  def initialize(client_id:, params:)
    super()
    @client_id = client_id
    @params = params
  end

  def call
    redirect_url = url_from_config
    redirect_url.query = encoded_params
    Response[redirect_url.to_s]
  end

  private

  attr_reader :client_id, :params
  attr_accessor :redirect_url

  def url_from_config
    URI(Rails.configuration.oauth.clients.dig(client_id.to_sym, :redirection_uri))
  end

  def encoded_params
    URI.encode_www_form(params_for_query)
  end

  def params_for_query
    params.collect { |key, value| [key.to_s, value] }
  end
end
