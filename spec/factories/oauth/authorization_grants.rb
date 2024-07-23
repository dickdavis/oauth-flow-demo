# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_authorization_grant, class: 'OAuth::AuthorizationGrant' do
    expires_at { 9.minutes.from_now }
    redeemed { false }
    user
    oauth_client

    transient do
      code_challenge do
        Base64.urlsafe_encode64(
          Digest::SHA256.digest('code_verifier'), padding: false
        )
      end
      code_challenge_method { 'S256' }
      redirect_uri { 'http://localhost:3000/' }
    end

    after :create do |oauth_authorization_grant, context|
      create(
        :oauth_challenge,
        oauth_authorization_grant:,
        code_challenge: context.code_challenge,
        code_challenge_method: context.code_challenge_method,
        redirect_uri: context.redirect_uri
      )
    end
  end
end
