# frozen_string_literal: true

FactoryBot.define do
  factory :oauth_session do
    access_token_jti { SecureRandom.uuid }
    refresh_token_jti { SecureRandom.uuid }
    status { 'created' }
    authorization_grant
  end
end
