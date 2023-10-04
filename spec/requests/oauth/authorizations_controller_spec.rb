# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AuthorizationsController do
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

    include_context 'with an authenticated client', :get, :oauth_authorize_path

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
        expect(response).to redirect_to(new_oauth_authorization_grant_path(state: body))
      end
    end
  end
end
