# frozen_string_literal: true

##
# Provides support for validating token claims
module OAuthSessionExchangeable
  extend ActiveSupport::Concern

  VALID_URIS = ['/api/v1/users/current'].freeze
  VALID_TOKEN_TYPES = ['urn:ietf:params:oauth:token-type:access_token'].freeze

  def validate_params_for_exchange!(resource:, subject_token_type:)
    raise OAuth::InvalidResourceError unless valid_resource?(resource)

    return if valid_subject_token_type?(subject_token_type)

    raise OAuth::InvalidSubjectTokenTypeError
  end

  private

  def valid_resource?(resource)
    resource.present? && VALID_URIS.include?(resource)
  end

  def valid_subject_token_type?(subject_token_type)
    subject_token_type.present? && VALID_TOKEN_TYPES.include?(subject_token_type)
  end
end
