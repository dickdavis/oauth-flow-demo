# frozen_string_literal: true

##
# Models an refresh token
class RefreshToken
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  OAUTH_CONFIG = Rails.configuration.oauth.freeze
  REVOCABLE_CLAIMS = %i[aud iss user_id].freeze
  EXPIRABLE_CLAIMS = %i[exp].freeze

  attr_accessor :aud, :exp, :iat, :iss, :jti, :user_id

  validates :jti, presence: true
  validate do
    errors.add(:jti, 'Invalid `jti` claim provided') unless oauth_session&.created_status?
  end

  validates :aud, presence: true, format: { with: /\A#{OAUTH_CONFIG.audience_url}*/ }

  validates :exp, presence: true
  validate do
    next if exp.blank?

    errors.add(:exp, 'is expired') if Time.zone.now > Time.zone.at(exp)
  end

  validates :iss, presence: true, format: { with: /\A#{OAUTH_CONFIG.issuer_url}\z/ }

  after_validation :expire_oauth_session, if: :errors_for_expirable_claims?
  after_validation :revoke_oauth_session, if: :errors_for_revocable_claims?

  private

  def oauth_session
    return @oauth_session if defined?(@oauth_session)

    @oauth_session = OAuthSession.find_by(refresh_token_jti: jti)
  end

  def user_id_from_oauth_session
    oauth_session&.user_id
  end

  def errors_for_revocable_claims?
    return false if skip_oauth_session_update?

    errors.attribute_names.intersect?(REVOCABLE_CLAIMS)
  end

  def revoke_oauth_session
    oauth_session.update(status: 'revoked')
  end

  def errors_for_expirable_claims?
    return false if skip_oauth_session_update?

    errors.attribute_names.intersect?(EXPIRABLE_CLAIMS)
  end

  def expire_oauth_session
    oauth_session.update(status: 'expired')
  end

  def skip_oauth_session_update?
    errors.blank? || errors.include?(:jti)
  end
end
