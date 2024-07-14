# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_authorization_request, class: 'OAuth::AuthorizationRequest' do
    client_id { 'client_id' }
    code_challenge { Base64.urlsafe_encode64(Digest::SHA256.digest('code_verifier'), padding: false) }
    code_challenge_method { 'S256' }
    redirect_uri { 'http://localhost:3000/' }
    response_type { 'code' }
    state { 'state' }
    oauth_client { nil }
  end
end
