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

  private

  def generate_expires_at
    self.expires_at ||= 5.minutes.from_now
  end

  def client_configuration
    return unless client_id

    client_config = Rails.configuration.oauth.clients[client_id.to_sym]
    errors.add(:client_id, 'Provided client_id does not map to a configured client') and return if client_config.blank?

    return unless client_config[:redirection_uri] != client_redirection_uri

    errors.add(:client_redirection_uri, 'Provided client_redirection_uri does not map to a configured client')
  end
end
