# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_authorization_grant, class: 'OAuth::AuthorizationGrant' do
    expires_at { 9.minutes.from_now }
    redeemed { false }
    user
    oauth_client
  end
end
