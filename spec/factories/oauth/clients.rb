# frozen_string_literal: true

##
# Factory for OAuth::Client model
FactoryBot.define do
  factory :oauth_client, class: 'OAuth::Client' do
    api_key { nil }
    name { 'Demo Client' }
    client_type { 'confidential' }
    redirect_uri { 'http://localhost:3000/' }
    access_token_duration { 300 }
    refresh_token_duration { 1_209_600 }
  end
end
