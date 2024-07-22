# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_token_exchange_grant, class: 'OAuth::TokenExchangeGrant' do
    user
    oauth_client
  end
end
