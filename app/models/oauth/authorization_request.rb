# frozen_string_literal: true

module OAuth
  ##
  # Models an authorization request token
  class AuthorizationRequest
    include ActiveModel::Model
    include ActiveModel::Validations

    VALID_CODE_CHALLENGE_METHODS = ['S256'].freeze
    VALID_RESPONSE_TYPES = ['code'].freeze

    attr_accessor :oauth_client, :client_id,
                  :code_challenge, :code_challenge_method,
                  :redirect_uri, :response_type, :state

    validates :response_type, presence: true, inclusion: { in: VALID_RESPONSE_TYPES }

    validate :oauth_client_must_be_valid
    validate :client_id_must_be_valid
    validate :pkce_params_must_be_valid
    validate :redirect_uri_must_be_valid

    def self.from_internal_state_token(token)
      attributes = JsonWebToken.decode(token)
      oauth_client = OAuth::Client.find_by(id: attributes[:oauth_client])
      new(
        **attributes.except(:oauth_client).merge(oauth_client:)
      )
    end

    def to_h
      {
        oauth_client: oauth_client.id,
        client_id: client,
        client_state:,
        code_challenge:,
        code_challenge_method:,
        redirect_uri:,
        response_type:
      }
    end

    def to_internal_state_token
      JsonWebToken.encode(to_h)
    end

    private

    def oauth_client_must_be_valid
      errors.add(:oauth_client, 'is invalid') unless valid_oauth_client?
    end

    def client_id_must_be_valid
      return unless oauth_client.is_a?(OAuth::Client)
      return if oauth_client.confidential_client_type? && client_id.blank?

      errors.add(:client_id, 'is required') and return if client_id.blank?

      client = OAuth::Client.find_by(id: client_id)
      errors.add(:client_id, 'does not map to an existing client') unless client
    end

    def pkce_params_must_be_valid
      return unless oauth_client.is_a?(OAuth::Client)

      validate_public_pkce_params if oauth_client.public_client_type?

      validate_confidential_pkce_params
    end

    def validate_public_pkce_params
      return unless valid_oauth_client?
      return unless oauth_client.public_client_type?

      validate_pkce_params
    end

    def validate_confidential_pkce_params
      return unless valid_oauth_client?
      unless oauth_client.confidential_client_type? && (code_challenge.present? || code_challenge_method.present?)
        return
      end

      validate_pkce_params
    end

    def validate_pkce_params
      errors.add(:code_challenge, 'is required') if code_challenge.blank?
      errors.add(:code_challenge_method, 'is required') if code_challenge_method.blank?
      errors.add(:code_challenge_method, 'is invalid') unless code_challenge_method.in?(VALID_CODE_CHALLENGE_METHODS)
    end

    def redirect_uri_must_be_valid
      return unless valid_oauth_client?
      return if oauth_client.confidential_client_type? && redirect_uri.blank?

      errors.add(:redirect_uri, 'is required') if redirect_uri.blank?
      errors.add(:redirect_uri, 'is not a valid') unless oauth_client.redirect_uri == redirect_uri
    end

    def valid_oauth_client?
      oauth_client.is_a?(OAuth::Client)
    end
  end
end
