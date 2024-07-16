# frozen_string_literal: true

RSpec.shared_examples 'an endpoint that requires token authentication' do
  context 'without an AUTHORIZATION header' do
    before do
      shared_context_headers.delete('AUTHORIZATION')
    end

    it 'responds with HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'without a malformed AUTHORIZATION header' do
    before do
      shared_context_headers['AUTHORIZATION'] = 'foobar'
    end

    it 'responds with HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'without a valid JWT in the AUTHORIZATION header' do
    before do
      shared_context_headers['AUTHORIZATION'] = 'Bearer foobar'
    end

    it 'responds with HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with a JWT with invalid claims in the AUTHORIZATION header' do
    let(:invalid_jwt) { JsonWebToken.encode({ foo: 'bar' }) }

    before do
      shared_context_headers['AUTHORIZATION'] = "Bearer #{invalid_jwt}"
    end

    it 'responds with HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with a access token from an invalid OAuth session in the AUTHORIZATION header' do
    let(:oauth_session) { create(:oauth_session, oauth_authorization_grant:, status: 'revoked') }
    let(:oauth_authorization_grant) { create(:oauth_authorization_grant, user:) }
    let(:oauth_access_token) { build(:oauth_access_token, oauth_session:) }
    let(:bearer_token_header) do
      { 'AUTHORIZATION' => "Bearer #{oauth_access_token.to_encoded_token}" }
    end

    before do
      oauth_session.update!(access_token_jti: oauth_access_token.jti)
    end

    it 'responds with HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

RSpec.shared_context 'with a valid access token' do |method, path|
  subject(:call_endpoint) { send(method, url, **options_for_request) }

  let(:url) { send(path) }
  let(:options_for_request) { { params: shared_context_params, headers: shared_context_headers } }
  let(:shared_context_params) { try(:params) || {} }
  let(:shared_context_headers) { (try(:headers) || {}).reverse_merge!(bearer_token_header) }

  let_it_be(:oauth_authorization_grant) { create(:oauth_authorization_grant, user:) }
  let_it_be(:oauth_session) { create(:oauth_session, oauth_authorization_grant:) }
  let_it_be(:oauth_access_token) { build(:oauth_access_token, oauth_session:) }

  let(:bearer_token_header) do
    { 'AUTHORIZATION' => "Bearer #{oauth_access_token.to_encoded_token}" }
  end
end
