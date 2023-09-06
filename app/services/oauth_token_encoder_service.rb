# frozen_string_literal: true

##
# Service which encodes access and refresh tokens.
class OAuthTokenEncoderService < ApplicationService
  Response = Data.define(:jti, :token)

  def initialize(client_id:, expiration:, optional_claims: {})
    super()
    @client_id = client_id
    @expiration = expiration
    @optional_claims = optional_claims
  end

  # rubocop:disable Metrics/AbcSize
  def call
    raise OAuth::ServerError, invalid_param_message(:client_id) unless valid_client_id?
    raise OAuth::ServerError, invalid_param_message(:expiration) unless valid_expiration?

    payload = {
      aud: oauth_config.audience_url,
      iat: Time.zone.now.to_i,
      iss: oauth_config.issuer_url,
      jti: SecureRandom.uuid
    }.merge(optional_claims)

    token = JsonWebToken.encode(payload, expiration)

    Response[payload[:jti], token]
  end
  # rubocop:enable Metrics/AbcSize

  private

  attr_reader :client_id, :expiration, :optional_claims

  def oauth_config
    @oauth_config ||= Rails.configuration.oauth
  end

  def valid_client_id?
    client_id.present? && oauth_config.clients.key?(client_id.to_sym)
  end

  def valid_expiration?
    expiration.is_a?(ActiveSupport::TimeWithZone)
  end

  def invalid_param_message(param)
    I18n.t("services.oauth_token_encoder_service.invalid_#{param}", value: send(param))
  end
end
