# frozen_string_literal: true

module OAuth
  ##
  # Models a challenge used in PKCE
  class Challenge < ApplicationRecord
    VALID_CODE_CHALLENGE_METHODS = %w[S256].freeze

    belongs_to :oauth_authorization_grant, class_name: 'OAuth::AuthorizationGrant'

    validates :code_challenge_method, allow_blank: true, inclusion: { in: VALID_CODE_CHALLENGE_METHODS }
  end
end
