# frozen_string_literal: true

require 'json_web_token'

##
# Service which encodes current sign-in state into a JWT token
class StateTokenEncoderService < ApplicationService
  Response = Data.define(:status, :body)

  VALID_CODE_CHALLENGE_METHODS = ['S256'].freeze
  VALID_RESPONSE_TYPES = ['code'].freeze

  def initialize(client_id:, client_state:, code_challenge:, code_challenge_method:, response_type:)
    super()
    @client_id = client_id
    @client_state = client_state
    @code_challenge = code_challenge
    @code_challenge_method = code_challenge_method
    @response_type = response_type
  end

  def call
    return Response[:bad_request, { errors: errors_from_params }] if errors_from_params.present?

    payload = { client_id:, client_state:, code_challenge:, code_challenge_method:, response_type: }
    Response[:ok, JsonWebToken.encode(payload)]
  end

  private

  attr_reader :client_id, :client_state, :code_challenge, :code_challenge_method, :response_type

  def errors_from_params
    @errors_from_params ||= [].tap do |errors|
      %i[client_id code_challenge code_challenge_method response_type].each do |param|
        if (error = validate_param(param))
          errors.push(error)
        end
      end
    end
  end

  def validate_param(param)
    invalid_param_message(param) unless send("valid_#{param}?".to_sym)
  end

  def invalid_param_message(param)
    I18n.t('services.state_token_encoder.invalid_param', param: param.to_s, value: send(param))
  end

  def valid_client_id?
    client_id.present? && Rails.configuration.oauth.clients[client_id.to_sym]
  end

  def valid_code_challenge?
    code_challenge.present?
  end

  def valid_code_challenge_method?
    code_challenge_method&.in?(VALID_CODE_CHALLENGE_METHODS)
  end

  def valid_response_type?
    response_type&.in?(VALID_RESPONSE_TYPES)
  end
end
