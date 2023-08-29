# frozen_string_literal: true

FactoryBot.define do
  factory :authorization_grant do
    code_challenge { Base64.urlsafe_encode64(Digest::SHA256.digest('code_verifier'), padding: false) }
    code_challenge_method { 'S256' }
    expires_at { 9.minutes.from_now }
    client_id { 'democlient' }
    client_redirection_uri { 'http://localhost:3000/' }
    redeemed { false }
    user
  end
end
