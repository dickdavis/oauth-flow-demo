# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_access_token_request, class: 'OAuth::AccessTokenRequest' do
    code_verifier { 'code_verifier' }
    redirect_uri { 'http://localhost:3000/' }
    oauth_authorization_grant
  end
end
