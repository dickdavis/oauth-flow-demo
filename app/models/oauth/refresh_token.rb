# frozen_string_literal: true

module OAuth
  ##
  # Models an refresh token
  class RefreshToken
    include OAuth::ClaimValidatable

    def self.default(exp:)
      new(
        aud: OAuth::CONFIG.audience_url,
        exp:,
        iat: Time.zone.now.to_i,
        iss: OAuth::CONFIG.issuer_url,
        jti: SecureRandom.uuid
      )
    end

    def self.from_token(token)
      new(JsonWebToken.decode(token))
    end

    def to_h
      { aud:, exp:, iat:, iss:, jti: }
    end

    def to_encoded_token
      JsonWebToken.encode(to_h, exp)
    end
  end
end
