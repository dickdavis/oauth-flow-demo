# frozen_string_literal: true

module OAuth
  ##
  # Models an access token
  class AccessToken
    include OAuth::ClaimValidatable

    attr_accessor :user_id

    validates :user_id, presence: true, comparison: { equal_to: :user_id_from_oauth_session }

    def to_h
      { aud:, exp:, iat:, iss:, jti:, user_id: }
    end

    private

    def user_id_from_oauth_session
      oauth_session&.user_id
    end
  end
end
