# frozen_string_literal: true

##
# Models an oauth session with minimal data from session.
class OAuthSession < ApplicationRecord
  STATUS_ENUM_VALUES = {
    created: 'created',
    expired: 'expired',
    refreshed: 'refreshed',
    revoked: 'revoked'
  }.freeze

  VALID_UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}/i

  validates :access_token_jti, presence: true, uniqueness: true, format: { with: VALID_UUID_REGEX }
  encrypts :access_token_jti, deterministic: true

  validates :refresh_token_jti, presence: true, uniqueness: true, format: { with: VALID_UUID_REGEX }
  encrypts :refresh_token_jti, deterministic: true

  belongs_to :authorization_grant

  enum status: STATUS_ENUM_VALUES, _suffix: true
end
