# frozen_string_literal: true

module OAuth
  ##
  # Models an access token
  class AccessToken
    include OAuth::ClaimValidatable

    attr_accessor :user_id

    validates :user_id, presence: true, comparison: { equal_to: :user_id_from_oauth_session }

    def self.default(exp:, user_id:)
      new(
        aud: OAuth::CONFIG.audience_url,
        exp:,
        iat: Time.zone.now.to_i,
        iss: OAuth::CONFIG.issuer_url,
        jti: SecureRandom.uuid,
        user_id:
      )
    end

    def self.from_token(token)
      new(JsonWebToken.decode(token))
    end

    def to_h
      { aud:, exp:, iat:, iss:, jti:, user_id: }
    end

    def to_encoded_token
      JsonWebToken.encode(to_h, exp)
    end

    private

    def user_id_from_oauth_session
      oauth_session&.user_id
    end
  end
end
