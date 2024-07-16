# frozen_string_literal: true

RSpec.shared_examples 'a model that creates OAuth sessions' do
  context 'when the oauth session is created' do
    it 'creates an OAuth::Session record' do
      expect { method_call }.to change(OAuth::Session, :count).by(1)
    end

    it 'returns a valid access token' do
      results = method_call
      expect(results.access_token).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
    end

    it 'returns an access token with valid aud, exp, iat, iss, jti, and user_id claims' do
      token = JsonWebToken.decode(method_call.access_token)
      aggregate_failures do
        expect(token[:aud]).to eq(Rails.configuration.oauth.audience_url)
        expect(token[:exp]).to be_a(Integer)
        expect(token[:iat]).to be_a(Integer)
        expect(token[:iss]).to eq(Rails.configuration.oauth.issuer_url)
        expect(token[:jti]).to match(OAuth::Session::VALID_UUID_REGEX)
        expect(token[:user_id]).to eq(oauth_authorization_grant.user_id)
      end
    end

    it 'saves the access_token_jti in the OAuth::Session' do
      results = method_call
      token = JsonWebToken.decode(results.access_token)
      expect(oauth_authorization_grant.active_oauth_session.access_token_jti).to eq(token[:jti])
    end

    it 'returns a valid refresh token' do
      results = method_call
      expect(results.refresh_token).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
    end

    it 'returns a refresh token with valid aud, exp, iat, iss, jti, and user_id claims' do
      token = JsonWebToken.decode(method_call.refresh_token)
      aggregate_failures do
        expect(token[:aud]).to eq(Rails.configuration.oauth.audience_url)
        expect(token[:exp]).to be_a(Integer)
        expect(token[:iat]).to be_a(Integer)
        expect(token[:iss]).to eq(Rails.configuration.oauth.issuer_url)
        expect(token[:jti]).to match(OAuth::Session::VALID_UUID_REGEX)
      end
    end

    it 'saves the refresh_token_jti in the OAuth::Session' do
      results = method_call
      token = JsonWebToken.decode(results.refresh_token)
      expect(oauth_authorization_grant.active_oauth_session.refresh_token_jti).to eq(token[:jti])
    end

    it 'returns the access token expiration' do
      Timecop.freeze(Time.zone.now) do
        results = method_call
        token = JsonWebToken.decode(results.access_token)
        expect(token[:exp]).to eq(results.expiration)
      end
    end
  end

  context 'when the oauth session fails to create' do
    let(:oauth_session_double) { build(:oauth_session, oauth_authorization_grant:, access_token_jti: nil) }

    before do
      allow(OAuth::Session).to receive(:new).and_return(oauth_session_double)
    end

    it 'raises an OAuth::ServerError' do
      expect { method_call }.to raise_error(
        OAuth::ServerError,
        "Failed to create OAuthSession. Errors: Access token JTI can't be blank, Access token JTI is invalid"
      )
    end
  end
end
