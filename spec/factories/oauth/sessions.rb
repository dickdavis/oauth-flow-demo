# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_session, class: 'OAuth::Session' do
    access_token_jti { SecureRandom.uuid }
    refresh_token_jti { SecureRandom.uuid }
    status { 'created' }
    oauth_authorization_grant
  end
end
