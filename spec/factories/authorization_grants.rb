# frozen_string_literal: true

FactoryBot.define do
  factory :authorization_grant do
    code_challenge { Digest::SHA256.base64digest('code_verifier').tr('+/', '-_').tr('=', '') }
    code_challenge_method { 'S256' }
    expires_at { 9.minutes.from_now }
    client_id { 'democlient' }
    client_redirection_uri { 'http://localhost:3000/' }
    user
  end
end
