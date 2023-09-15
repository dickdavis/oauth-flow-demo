# frozen_string_literal: true

RSpec.shared_examples 'a model that creates OAuth sessions' do
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
      expect(authorization_grant.active_oauth_session.access_token_jti).to eq(token[:jti])
    end

    it 'returns a valid refresh token' do
      results = method_call
      expect(results.refresh_token).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
    end

    it 'saves the refresh_token_jti in the OAuthSession' do
      results = method_call
      token = JsonWebToken.decode(results.refresh_token)
      expect(authorization_grant.active_oauth_session.refresh_token_jti).to eq(token[:jti])
    end

    it 'returns the access token expiration' do
      results = method_call
      token = JsonWebToken.decode(results.access_token)
      expect(token[:exp]).to eq(results.expiration)
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
