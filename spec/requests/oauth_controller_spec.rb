# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_context 'with an authenticated client' do |method, path|
  subject(:call_endpoint) { send(method, url, **options_for_request) }

  let(:url) { send(path) }
  let(:options_for_request) { { params: shared_context_params, headers: shared_context_headers } }
  let(:shared_context_params) { params.reverse_merge!(client_id: 'democlient') }
  let(:shared_context_headers) { headers.reverse_merge!(http_basic_auth_header) }

  def http_basic_auth_header
    client_id = 'democlient'
    client_secret = Rails.application.credentials.clients[client_id.to_sym]
    auth = ActionController::HttpAuthentication::Basic.encode_credentials(client_id, client_secret)
    { 'HTTP_AUTHORIZATION' => auth }
  end
end

RSpec.shared_examples 'an endpoint that requires client authentication' do
  context 'with client_id param that does not match client id in header' do
    let(:shared_context_params) { super().merge(client_id: 'negativetestclient') }

    it 'returns HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns an access denied message' do
      call_endpoint
      expect(response.body.chomp).to eq('HTTP Basic: Access denied.')
    end
  end

  context 'without HTTP basic auth header' do
    let(:shared_context_headers) { super().except('HTTP_AUTHORIZATION') }

    it 'returns HTTP status unauthorized' do
      call_endpoint
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns an access denied message' do
      call_endpoint
      expect(response.body.chomp).to eq('HTTP Basic: Access denied.')
    end
  end
end

RSpec.describe OAuthController do
  describe 'GET /authorize' do
    let(:headers) { {} }
    let(:params) { { client_id:, state:, code_challenge:, code_challenge_method:, response_type: } }
    let(:client_id) { 'democlient' }
    let(:state) { 'foobar' }
    let(:code_challenge) { 'code_challenge' }
    let(:code_challenge_method) { 'S256' }
    let(:response_type) { 'code' }

    let(:state_token_encoder_service) { instance_double(StateTokenEncoderService, call: results) }
    let(:results) { StateTokenEncoderService::Response[status, body] }

    let(:client_redirect_url_service) { instance_double(ClientRedirectUrlService, call: redirect_results) }
    let(:redirect_results) { ClientRedirectUrlService::Response[redirect_url] }
    let(:redirect_url) { 'http://localhost:3000/callback?code=foo&state=bar' }

    before do
      allow(StateTokenEncoderService).to receive(:new).and_return(state_token_encoder_service)
      allow(ClientRedirectUrlService).to receive(:new).and_return(client_redirect_url_service)
    end

    include_context 'with an authenticated client', :get, :authorize_path

    it_behaves_like 'an endpoint that requires client authentication'

    context 'when the client_id param is missing' do
      let(:shared_context_params) { super().except!(:client_id) }

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when state token encoder service returns invalid_request status' do
      let(:status) { :invalid_request }
      let(:body) { { errors: 'foobar' } }

      it 'calls the state token encoder service with the params' do
        call_endpoint
        expect(StateTokenEncoderService).to have_received(:new).with(
          client_id:,
          client_state: state,
          code_challenge:,
          code_challenge_method:,
          response_type:
        )
      end

      it 'redirects to client redirection_uri with state and error params' do
        call_endpoint
        expect(response).to redirect_to(redirect_url)
      end

      context 'when the client redirect url service raises an error' do
        before do
          allow(client_redirect_url_service).to receive(:call).and_raise(OAuth::InvalidRedirectUrlError)
        end

        it 'responds with HTTP status bad request' do
          call_endpoint
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context 'when state token encoder service returns ok status' do
      let(:status) { :ok }
      let(:body) { 'state token' }

      it 'calls the state token encoder service with the params' do
        call_endpoint
        expect(StateTokenEncoderService).to have_received(:new).with(
          client_id:,
          client_state: state,
          code_challenge:,
          code_challenge_method:,
          response_type:
        )
      end

      it 'redirects the user to the authorization grant page' do
        call_endpoint
        expect(response).to redirect_to(new_authorization_grant_path(state: body))
      end
    end
  end

  describe 'POST /token' do
    let(:headers) { {} }
    let(:params) { { code:, code_verifier:, grant_type: } }
    let(:grant_type) { 'authorization_code' }
    let(:code_verifier) { 'code_verifier' }
    let(:code) { authorization_grant.id }
    let(:authorization_grant) { create(:authorization_grant, user:) }
    let(:user) { create(:user) }

    let(:token_request_validator_service) { instance_double(TokenRequestValidatorService, call!: true) }
    let(:oauth_token_encoder_service) { instance_double(OAuthTokenEncoderService) }
    let(:access_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'access_token'] }
    let(:refresh_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'refresh_token'] }

    before do
      allow(TokenRequestValidatorService).to receive(:new).and_return(token_request_validator_service)
      allow(OAuthTokenEncoderService).to receive(:new).and_return(oauth_token_encoder_service)
      allow(oauth_token_encoder_service).to receive(:call).and_return(access_token_results, refresh_token_results)
    end

    include_context 'with an authenticated client', :post, :token_path

    it_behaves_like 'an endpoint that requires client authentication'

    it 'calls the token request validator service with the params' do
      call_endpoint
      expect(TokenRequestValidatorService).to have_received(:new).with(
        authorization_grant:,
        code_verifier:,
        grant_type:
      )
    end

    context 'when the token request validator services raises the unsupported grant type error' do
      before do
        allow(token_request_validator_service).to receive(:call!).and_raise(OAuth::UnsupportedGrantTypeError)
      end

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with error unsupported_grant_type as JSON' do
        call_endpoint
        expect(response.parsed_body).to eq({ 'error' => 'unsupported_grant_type' })
      end
    end

    context 'when the token request validator services raises the invalid grant error' do
      before do
        allow(token_request_validator_service).to receive(:call!).and_raise(OAuth::InvalidGrantError)
      end

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with error invalid_grant as JSON' do
        call_endpoint
        expect(response.parsed_body).to eq({ 'error' => 'invalid_grant' })
      end
    end

    context 'when the token request validator services raises the invalid request error' do
      before do
        allow(token_request_validator_service).to receive(:call!).and_raise(OAuth::InvalidTokenRequestError)
      end

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with error invalid_grant as JSON' do
        call_endpoint
        expect(response.parsed_body).to eq({ 'error' => 'invalid_request' })
      end
    end

    context 'when the token request validator service does not raise an error' do
      it 'creates an OAuthSession record' do
        expect { call_endpoint }.to change(OAuthSession, :count).by(1)
      end

      it 'responds with HTTP status ok' do
        call_endpoint
        expect(response).to have_http_status(:ok)
      end

      it 'renders the serialized token data' do
        call_endpoint
        expect(response.parsed_body).to include(
          {
            'access_token' => 'access_token',
            'refresh_token' => 'refresh_token',
            'token_type' => 'bearer',
            'expires_in' => 5.minutes.from_now.to_i
          }
        )
      end

      context 'when oauth token creation raises the server error' do
        let(:authorization_grant_spy) { instance_spy(AuthorizationGrant) }

        before do
          allow(AuthorizationGrant).to receive(:find_by).and_return(authorization_grant_spy)
          allow(authorization_grant_spy).to receive(:create_oauth_session).and_raise(OAuth::ServerError, 'foobar')
        end

        it 'responds with HTTP status internal_server_error' do
          call_endpoint
          expect(response).to have_http_status(:internal_server_error)
        end

        it 'responds with error server_error as JSON' do
          call_endpoint
          expect(response.parsed_body).to eq({ 'error' => 'server_error' })
        end
      end
    end
  end
end
