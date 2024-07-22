# frozen_string_literal: true

module OAuth
  ##
  # Models token exchange grant.
  class TokenExchangeGrant < ApplicationRecord
    include OAuth::SessionCreatable

    belongs_to :user
    belongs_to :oauth_client, class_name: 'OAuth::Client'
    has_many :oauth_sessions,
             class_name: 'OAuth::Session',
             foreign_key: :oauth_authorization_grant_id,
             inverse_of: :oauth_authorization_grant,
             dependent: :destroy
  end
end
