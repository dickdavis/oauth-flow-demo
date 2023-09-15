# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token, class: 'RefreshToken' do
    transient do
      oauth_session { association(:oauth_session) }
    end

    aud { Rails.configuration.oauth[:audience_url] }
    exp { 14.days.from_now.to_i }
    iat { Time.zone.now.to_i }
    iss { Rails.configuration.oauth[:issuer_url] }
    jti { oauth_session.refresh_token_jti }

    initialize_with { new(aud:, exp:, iat:, iss:, jti:) }
  end
end
