# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuthTokenEncoderService do # rubocop:disable RSpec/FilePath
  describe '.call' do
    subject(:service_call) do
      described_class.new(client_id:, expiration:, optional_claims:).call
    end

    let(:client_id) { 'democlient' }
    let(:expiration) { 5.minutes.from_now }
    let(:optional_claims) { {} }

    context 'with invalid client_id provided' do
      let(:client_id) { nil }

      it 'raises an OAuth::ServerError' do
        expect { service_call }.to raise_error(
          OAuth::ServerError, I18n.t('services.oauth_token_encoder_service.invalid_client_id', value: client_id)
        )
      end
    end

    context 'with invalid expiration provided' do
      let(:expiration) { 5.minutes.from_now.to_s }

      it 'raises an OAuth::ServerError' do
        expect { service_call }.to raise_error(
          OAuth::ServerError, I18n.t('services.oauth_token_encoder_service.invalid_expiration', value: expiration)
        )
      end
    end

    context 'with valid params provided' do
      it 'returns a valid JWT token' do
        expect(service_call.token).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
      end

      it 'returns a token with a valid aud claim' do
        token = JsonWebToken.decode(service_call.token)
        expect(token[:aud]).to eq(Rails.configuration.oauth.audience_url)
      end

      it 'returns a token with a valid exp claim' do
        token = JsonWebToken.decode(service_call.token)
        expect(token[:exp]).to eq(expiration.to_i)
      end

      it 'returns a token with a valid iat claim' do
        token = JsonWebToken.decode(service_call.token)
        expect(token[:iat]).to be_a(Integer)
      end

      it 'returns a token with a valid iss claim' do
        token = JsonWebToken.decode(service_call.token)
        expect(token[:iss]).to eq(Rails.configuration.oauth.issuer_url)
      end

      it 'returns a token with a valid jti claim' do
        token = JsonWebToken.decode(service_call.token)
        expect(token[:jti]).to match(OAuthSession::VALID_UUID_REGEX)
      end

      it 'returns jti which matches the jti in the token' do
        jti, token = service_call.deconstruct
        parsed_token = JsonWebToken.decode(token)
        expect(jti).to match(parsed_token[:jti])
      end

      context 'with optional claims provided' do
        let(:optional_claims) { { foo: 'bar' } }

        it 'returns a token with the optional claims provided' do
          token = JsonWebToken.decode(service_call.token)
          expect(token[:foo]).to eq('bar')
        end
      end
    end
  end
end
