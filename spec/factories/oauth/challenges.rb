# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_challenge, class: 'OAuth::Challenge' do
    code_challenge { Base64.urlsafe_encode64(Digest::SHA256.digest('code_verifier'), padding: false) }
    code_challenge_method { 'S256' }
    client_redirection_uri { 'http://localhost:3000/' }
    oauth_authorization_grant
  end
end
