# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_token, class: 'OAuth::AccessToken' do
    transient do
      oauth_session { association(:oauth_session) }
    end

    aud { Rails.configuration.oauth[:audience_url] }
    exp { 5.minutes.from_now.to_i }
    iat { Time.zone.now.to_i }
    iss { Rails.configuration.oauth[:issuer_url] }
    jti { oauth_session.access_token_jti }
    user_id { oauth_session.user_id }

    initialize_with { new(aud:, exp:, iat:, iss:, jti:, user_id:) }
  end
end
