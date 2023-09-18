# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::SessionsController do # rubocop:disable RSpec/FilePath
  describe 'POST /token' do
    let(:headers) { {} }
    let(:params) { { code:, code_verifier:, grant_type: } }
    let(:grant_type) { 'authorization_code' }
    let(:code_verifier) { 'code_verifier' }
    let(:code) { authorization_grant.id }
    let(:authorization_grant) { create(:authorization_grant, user:) }
    let(:user) { create(:user) }

    let(:oauth_token_encoder_service) { instance_double(OAuthTokenEncoderService) }
    let(:access_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'access_token'] }
    let(:refresh_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'refresh_token'] }

    before do
      allow(OAuthTokenEncoderService).to receive(:new).and_return(oauth_token_encoder_service)
      allow(oauth_token_encoder_service).to receive(:call).and_return(access_token_results, refresh_token_results)
    end

    include_context 'with an authenticated client', :post, :oauth_token_path

    it_behaves_like 'an endpoint that requires client authentication'

    context 'when the client provides an unsupported grant type' do
      let(:grant_type) { 'foobar' }

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with error unsupported_grant_type as JSON' do
        call_endpoint
        expect(response.parsed_body).to eq({ 'error' => 'unsupported_grant_type' })
      end
    end

    context 'when the authorization grant is not found' do
      let(:code) { 'foobar' }

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with error invalid_grant as JSON' do
        call_endpoint
        expect(response.parsed_body).to eq({ 'error' => 'invalid_grant' })
      end
    end

    context 'when the authorization grant has already been redeemed' do
      let(:authorization_grant) { create(:authorization_grant, user:, redeemed: true) }

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with error invalid_grant as JSON' do
        call_endpoint
        expect(response.parsed_body).to eq({ 'error' => 'invalid_grant' })
      end
    end

    context 'when an invalid code verifier is provided' do
      let(:code_verifier) { 'foobar' }

      it 'responds with HTTP status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with error invalid_grant as JSON' do
        call_endpoint
        expect(response.parsed_body).to eq({ 'error' => 'invalid_request' })
      end
    end

    context 'when all params are valid' do
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
        let(:authorization_grant_spy) { instance_spy(AuthorizationGrant, blank?: false, redeemed?: false) }

        before do
          allow(AuthorizationGrant).to receive(:find_by).and_return(authorization_grant_spy)
          allow(authorization_grant_spy).to receive(:redeem).and_raise(OAuth::ServerError, 'foobar')
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
