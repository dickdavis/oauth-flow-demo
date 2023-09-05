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

  context 'without a valid JWT in the AUTHORIZATION header' do
    before do
      shared_context_headers['AUTHORIZATION'] = 'foobar'
    end

    it 'responds with HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'with an access token with invalid claims in the AUTHORIZATION header' do
    let(:oauth_session) { create(:oauth_session, authorization_grant:) }
    let(:authorization_grant) { create(:authorization_grant, user:) }

    before do
      _, token = OAuthTokenEncoderService.call(
        client_id: 'democlient',
        expiration: 5.minutes.ago,
        optional_claims: { user_id: user.id, jti: oauth_session.access_token_jti }
      ).deconstruct
      shared_context_headers['AUTHORIZATION'] = token
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
  let(:shared_context_params) { params }
  let(:shared_context_headers) { headers.reverse_merge!(bearer_token_header) }

  let(:authorization_grant) { create(:authorization_grant, user:) }
  let(:oauth_session) { create(:oauth_session, authorization_grant:) }

  def bearer_token_header
    _, token = OAuthTokenEncoderService.call(
      client_id: 'democlient',
      expiration: Rails.configuration.oauth.access_token_expiration.minutes.from_now,
      optional_claims: { user_id: user.id, jti: oauth_session.access_token_jti }
    ).deconstruct

    { 'AUTHORIZATION' => "Bearer #{token}" }
  end
end
