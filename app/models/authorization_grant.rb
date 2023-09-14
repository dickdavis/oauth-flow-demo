# frozen_string_literal: true

##
# Models an authorization grant.
class AuthorizationGrant < ApplicationRecord
  VALID_CODE_CHALLENGE_METHODS = %w[S256].freeze

  belongs_to :user
  has_many :oauth_sessions, dependent: :destroy

  before_validation :generate_expires_at

  validates :code_challenge, presence: true
  validates :code_challenge_method, presence: true, inclusion: { in: VALID_CODE_CHALLENGE_METHODS }
  validates :expires_at, comparison: { less_than: 10.minutes.from_now }
  validates :client_id, presence: true
  validates :client_redirection_uri, presence: true

  validate :client_configuration

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def create_oauth_session
    access_token_expiration = oauth_config.access_token_expiration.minutes.from_now

    access_token_jti, access_token = OAuthTokenEncoderService.call(
      client_id:,
      expiration: access_token_expiration,
      optional_claims: { user_id: }
    ).deconstruct

    refresh_token_jti, refresh_token = OAuthTokenEncoderService.call(
      client_id:,
      expiration: oauth_config.refresh_token_expiration.minutes.from_now
    ).deconstruct

    oauth_session = oauth_sessions.new(access_token_jti:, refresh_token_jti:)
    if oauth_session.save
      update(redeemed: true) unless redeemed?
      Data
        .define(:access_token, :refresh_token, :expiration)
        .new(access_token, refresh_token, access_token_expiration.to_i)
    else
      errors = oauth_session.errors.full_messages.join(', ')
      raise OAuth::ServerError, I18n.t('oauth.server_error.oauth_session_failure', errors:)
    end
  rescue OAuth::InvalidTokenParamError => error
    raise OAuth::ServerError, error.message
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def oauth_config
    @oauth_config ||= Rails.configuration.oauth
  end

  def generate_expires_at
    self.expires_at ||= 5.minutes.from_now
  end

  def client_configuration
    return unless client_id

    client_config = oauth_config.clients[client_id.to_sym]
    errors.add(:client_id, 'Provided client_id does not map to a configured client') and return if client_config.blank?

    return unless client_config[:redirection_uri] != client_redirection_uri

    errors.add(:client_redirection_uri, 'Provided client_redirection_uri does not map to a configured client')
  end
end
