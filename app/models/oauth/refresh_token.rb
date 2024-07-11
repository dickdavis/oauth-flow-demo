# frozen_string_literal: true

module OAuth
  ##
  # Models an refresh token
  class RefreshToken
    include OAuth::ClaimValidatable
  end
end
