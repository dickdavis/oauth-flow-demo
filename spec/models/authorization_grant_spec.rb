# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationGrant do
  subject(:model) { build(:authorization_grant) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:code_challenge) }
    it { is_expected.to validate_presence_of(:code_challenge_method) }
    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_presence_of(:client_redirection_uri) }
    it { is_expected.to allow_value(5.minutes.from_now).for(:expires_at) }
    it { is_expected.not_to allow_value(10.minutes.from_now).for(:expires_at) }

    it 'adds an error if client_id is not configured' do
      model.client_id = 'invalidclient'
      model.save
      expect(model.errors).to include(:client_id)
    end

    it 'does not add an error if client_id is configured' do
      model.client_id = 'democlient'
      model.save
      expect(model.errors).not_to include(:client_id)
    end

    it 'adds an error if client_redirection_uri does not match client configuration' do
      model.client_redirection_uri = 'http://not-configured.for/client'
      model.save
      expect(model.errors).to include(:client_redirection_uri)
    end

    it 'does not add an error if client_redirect_uri matches client configuration' do
      model.client_id = 'http://localhost:3000/'
      model.save
      expect(model.errors).not_to include(:client_redirection_uri)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:oauth_sessions) }
  end

  describe '#create_oauth_session' do
    subject(:method_call) { authorization_grant.create_oauth_session }

    let(:authorization_grant) { create(:authorization_grant) }

    context 'when the token request validator service does not raise an error' do
      it 'calls the oauth token encoder service to create both the access and refresh tokens' do
        allow(OAuthTokenEncoderService).to receive(:new).and_call_original
        method_call
        expect(OAuthTokenEncoderService).to have_received(:new).exactly(2).times
      end

      it 'creates an OAuthSession record' do
        expect { method_call }.to change(OAuthSession, :count).by(1)
      end

      it 'returns a valid access token' do
        results = method_call
        expect(results.access_token).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
      end

      it 'saves the access_token_jti in the OAuthSession' do
        results = method_call
        token = JsonWebToken.decode(results.access_token)
        expect(OAuthSession.last.access_token_jti).to eq(token[:jti])
      end

      it 'returns a valid refresh token' do
        results = method_call
        expect(results.refresh_token).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
      end

      it 'saves the refresh_token_jti in the OAuthSession' do
        results = method_call
        token = JsonWebToken.decode(results.refresh_token)
        expect(OAuthSession.last.refresh_token_jti).to eq(token[:jti])
      end

      it 'returns the access token expiration' do
        results = method_call
        token = JsonWebToken.decode(results.access_token)
        expect(token[:exp]).to eq(results.expiration)
      end

      context 'when the authorization grant has not been redeemed' do
        it 'updates the redeemed attribute' do
          expect { method_call }.to change(authorization_grant, :redeemed).from(false).to(true)
        end
      end

      context 'when the authorization grant has already been redeemed' do
        let(:authorization_grant) { create(:authorization_grant, redeemed: true) }

        it 'does not update the redeemed attribute' do
          expect { method_call }.not_to change(authorization_grant, :redeemed)
        end
      end
    end

    context 'when the oauth token encoder service raises the invalid request error' do
      before do
        allow(OAuthTokenEncoderService).to receive(:new).and_raise(OAuth::InvalidTokenParamError, 'foobar')
      end

      it 'raises an OAuth::ServerError' do
        expect { method_call }.to raise_error(OAuth::ServerError, 'foobar')
      end
    end

    context 'when the oauth session fails to create' do
      let(:oauth_session_double) { build(:oauth_session, authorization_grant:, access_token_jti: nil) }

      before do
        allow(OAuthSession).to receive(:new).and_return(oauth_session_double)
      end

      it 'raises an OAuth::ServerError' do
        expect { method_call }.to raise_error(
          OAuth::ServerError,
          "Failed to create OAuthSession. Errors: Access token jti can't be blank, Access token jti is invalid"
        )
      end
    end
  end
end
