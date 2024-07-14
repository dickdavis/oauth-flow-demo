# frozen_string_literal: true

module OAuth
  ##
  # OAuth::Client model
  class Client < ApplicationRecord
    CLIENT_TYPE_ENUM_VALUES = { public: 'public', confidential: 'confidential' }.freeze

    enum client_type: CLIENT_TYPE_ENUM_VALUES, _suffix: true

    encrypts :api_key

    validates :name, presence: true, length: { minimum: 3, maximum: 255 }
    validates :access_token_duration, numericality: { only_integer: true, greater_than: 0 }
    validates :refresh_token_duration, numericality: { only_integer: true, greater_than: 0 }
    validates :redirect_uri, presence: true
    validate :redirect_uri_is_valid_uri

    before_create :generate_api_key

    def new_authorization_grant(user:, challenge_params: {})
      OAuth::AuthorizationGrant.create(oauth_client: self, user:, oauth_challenge_attributes: challenge_params)
    end

    # rubocop:disable Metrics/ParameterLists
    def new_authorization_request(client_id:, code_challenge:, code_challenge_method:, redirect_uri:, response_type:, state:) # rubocop:disable Layout/LineLength
      OAuth::AuthorizationRequest.new(
        oauth_client: self,
        client_id:,
        state:,
        code_challenge:,
        code_challenge_method:,
        redirect_uri:,
        response_type:
      )
    end
    # rubocop:enable Metrics/ParameterLists

    def url_for_redirect(params:)
      uri = URI(redirect_uri)
      params_for_query = params.collect { |key, value| [key.to_s, value] }
      encoded_params = URI.encode_www_form(params_for_query)
      uri.query = encoded_params
      uri.to_s
    rescue URI::InvalidURIError, ArgumentError, NoMethodError => error
      raise OAuth::InvalidRedirectUrlError, error.message
    end

    private

    def redirect_uri_is_valid_uri
      uri = URI.parse(redirect_uri)
      errors.add(:redirect_uri, 'must contain HTTP scheme') unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      errors.add(:redirect_uri, 'is not a valid URI')
    end

    def generate_api_key
      return if client_type == 'public'

      self.api_key = SecureRandom.hex
    end
  end
end
