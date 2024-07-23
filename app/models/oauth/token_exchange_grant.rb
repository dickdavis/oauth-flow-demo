# frozen_string_literal: true

module OAuth
  ##
  # Models token exchange grant.
  class TokenExchangeGrant < ApplicationRecord
    include OAuth::SessionCreatable

    belongs_to :user
    belongs_to :oauth_client, class_name: 'OAuth::Client'
  end
end
