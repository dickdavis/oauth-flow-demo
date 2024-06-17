# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::SessionsController do
  describe 'POST /token (grant_type="authorization_code")' do
    let_it_be(:user) { create(:user) }
    let_it_be(:authorization_grant) { create(:authorization_grant, user:) }
    let(:params) { { code:, code_verifier:, grant_type: } }
    let(:grant_type) { 'authorization_code' }
    let(:code_verifier) { 'code_verifier' }
    let(:code) { authorization_grant.id }

    include_context 'with an authenticated client', :post, :oauth_create_session_path

    it_behaves_like 'an endpoint that requires client authentication'

    context 'when the authorization grant is not found' do
      let(:code) { 'foobar' }

      it 'responds with HTTP status bad request and error invalid_grant as JSON' do
        call_endpoint
        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body).to eq({ 'error' => 'invalid_grant' })
        end
      end
    end

    context 'when the authorization grant has already been redeemed' do
      let(:authorization_grant) { create(:authorization_grant, user:, redeemed: true) }

      it 'responds with HTTP status bad request and error invalid_grant as JSON' do
        call_endpoint
        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body).to eq({ 'error' => 'invalid_grant' })
        end
      end
    end

    context 'when an invalid code verifier is provided' do
      let(:code_verifier) { 'foobar' }

      it 'responds with HTTP status bad request and error invalid_grant as JSON' do
        call_endpoint
        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body).to eq({ 'error' => 'invalid_request' })
        end
      end
    end

    context 'when all params are valid' do
      let(:oauth_token_encoder_service) { instance_double(OAuthTokenEncoderService) }
      let(:access_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'access_token'] }
      let(:refresh_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'refresh_token'] }

      before do
        allow(OAuthTokenEncoderService).to receive(:new).and_return(oauth_token_encoder_service)
        allow(oauth_token_encoder_service).to receive(:call).and_return(access_token_results, refresh_token_results)
      end

      it 'creates an OAuth session and serializes the token data' do # rubocop:disable RSpec/ExampleLength
        aggregate_failures do
          expect { call_endpoint }.to change(OAuthSession, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(
            {
              'access_token' => 'access_token',
              'refresh_token' => 'refresh_token',
              'token_type' => 'bearer',
              'expires_in' => 5.minutes.from_now.to_i
            }
          )
        end
      end

      context 'when oauth token creation raises the server error' do
        let(:authorization_grant_spy) { instance_spy(AuthorizationGrant, blank?: false, redeemed?: false) }

        before do
          allow(AuthorizationGrant).to receive(:find_by).and_return(authorization_grant_spy)
          allow(authorization_grant_spy).to receive(:redeem).and_raise(OAuth::ServerError, 'foobar')
        end

        it 'responds with HTTP status internal_server_error and error server_error as JSON' do
          call_endpoint
          aggregate_failures do
            expect(response).to have_http_status(:internal_server_error)
            expect(response.parsed_body).to eq({ 'error' => 'server_error' })
          end
        end
      end
    end
  end

  describe 'POST /token (grant_type="refresh_token")' do
    let_it_be(:user) { create(:user) }
    let_it_be(:authorization_grant) { create(:authorization_grant, user:) }
    let(:params) { { grant_type:, refresh_token: } }
    let(:grant_type) { 'refresh_token' }
    let(:refresh_token) { JsonWebToken.encode(attributes_for(:refresh_token, oauth_session:)) }
    let!(:oauth_session) { create(:oauth_session, authorization_grant:) }

    include_context 'with an authenticated client', :post, :oauth_refresh_session_path

    it_behaves_like 'an endpoint that requires client authentication'

    context 'when the client provides an invalid JWT for refresh token' do
      let(:refresh_token) { 'foobar' }

      it 'responds with HTTP status bad request and error unsupported_grant_type as JSON' do
        call_endpoint
        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body).to eq({ 'error' => 'invalid_request' })
        end
      end
    end

    context 'when oauth token creation raises the revoked session error' do
      let(:oauth_session) { create(:oauth_session, authorization_grant:, status: 'refreshed') }

      it 'responds with HTTP status bad request and error invalid_request as JSON' do
        call_endpoint
        aggregate_failures do
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body).to eq({ 'error' => 'invalid_request' })
        end
      end

      context 'with the same oauth session' do
        it 'logs the refresh replay attack details' do # rubocop:disable RSpec/ExampleLength
          logger_spy = instance_spy(ActiveSupport::Logger)
          allow(Rails).to receive(:logger).and_return(logger_spy)
          call_endpoint
          expect(logger_spy)
            .to have_received(:warn)
            .with(
              I18n.t(
                'oauth.revoked_session_error',
                client_id: authorization_grant.client_id,
                refreshed_session_id: oauth_session.id,
                revoked_session_id: oauth_session.id,
                user_id: user.id
              )
            )
        end
      end

      context 'with a different active oauth session' do
        it 'logs the refresh replay attack details' do # rubocop:disable RSpec/ExampleLength
          active_oauth_session = create(:oauth_session, authorization_grant:)
          logger_spy = instance_spy(ActiveSupport::Logger)
          allow(Rails).to receive(:logger).and_return(logger_spy)
          call_endpoint
          expect(logger_spy)
            .to have_received(:warn)
            .with(
              I18n.t(
                'oauth.revoked_session_error',
                client_id: authorization_grant.client_id,
                refreshed_session_id: oauth_session.id,
                revoked_session_id: active_oauth_session.id,
                user_id: user.id
              )
            )
        end
      end
    end

    context 'when all params are valid' do
      let(:oauth_token_encoder_service) { instance_double(OAuthTokenEncoderService) }
      let(:access_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'access_token'] }
      let(:refresh_token_results) { OAuthTokenEncoderService::Response[SecureRandom.uuid, 'refresh_token'] }

      before do
        allow(OAuthTokenEncoderService).to receive(:new).and_return(oauth_token_encoder_service)
        allow(oauth_token_encoder_service).to receive(:call).and_return(access_token_results, refresh_token_results)
      end

      it 'creates an OAuth session and responds with the serialized token data' do # rubocop:disable RSpec/ExampleLength
        aggregate_failures do
          expect { call_endpoint }.to change(OAuthSession, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include(
            {
              'access_token' => 'access_token',
              'refresh_token' => 'refresh_token',
              'token_type' => 'bearer',
              'expires_in' => 5.minutes.from_now.to_i
            }
          )
        end
      end

      context 'when oauth token creation raises the server error' do
        let(:oauth_session_spy) { instance_spy(OAuthSession) }

        before do
          allow(OAuthSession).to receive(:find_by).and_return(oauth_session_spy)
          allow(oauth_session_spy).to receive(:refresh).and_raise(OAuth::ServerError, 'foobar')
        end

        it 'responds with HTTP status internal_server_error and error server_error as JSON' do
          call_endpoint
          aggregate_failures do
            expect(response).to have_http_status(:internal_server_error)
            expect(response.parsed_body).to eq({ 'error' => 'server_error' })
          end
        end
      end
    end
  end

  describe 'POST /token (grant_type={ NOT `authorization_code` or `refresh_token` })' do
    let_it_be(:user) { create(:user) }
    let_it_be(:authorization_grant) { create(:authorization_grant, user:) }
    let(:params) { { code:, code_verifier:, grant_type: } }
    let(:grant_type) { 'foobar' }
    let(:code_verifier) { 'code_verifier' }
    let(:code) { authorization_grant.id }

    include_context 'with an authenticated client', :post, :oauth_unsupported_grant_type_path

    it_behaves_like 'an endpoint that requires client authentication'

    it 'responds with HTTP status bad request and error unsupported_grant_type as JSON' do
      call_endpoint
      aggregate_failures do
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq({ 'error' => 'unsupported_grant_type' })
      end
    end
  end

  describe 'POST /revoke (token_type_hint={ NOT `access_token` or `refresh_token` })' do
    let_it_be(:user) { create(:user) }
    let_it_be(:authorization_grant) { create(:authorization_grant, user:, redeemed: true) }
    let(:params) { { token:, token_type_hint: 'foobar' } }
    let(:token) { JsonWebToken.encode(attributes_for(:access_token, oauth_session:)) }
    let(:oauth_session) { create(:oauth_session, authorization_grant:) }

    include_context 'with an authenticated client', :post, :oauth_revoke_path

    it_behaves_like 'an endpoint that requires client authentication'

    it 'invokes the domain logic for revocation via generic lookup' do
      allow(OAuthSession).to receive(:revoke_for_token).and_return(true)
      call_endpoint
      expect(OAuthSession).to have_received(:revoke_for_token)
    end

    it 'responds with HTTP status ok' do
      call_endpoint
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /revoke (token_type_hint=access_token)' do
    let_it_be(:user) { create(:user) }
    let_it_be(:authorization_grant) { create(:authorization_grant, user:, redeemed: true) }
    let(:params) { { token:, token_type_hint: 'access_token' } }
    let(:token) { JsonWebToken.encode(attributes_for(:access_token, oauth_session:)) }
    let(:oauth_session) { create(:oauth_session, authorization_grant:) }

    include_context 'with an authenticated client', :post, :oauth_revoke_access_token_path

    it_behaves_like 'an endpoint that requires client authentication'

    it 'invokes the domain logic for revocation via generic lookup' do
      allow(OAuthSession).to receive(:revoke_for_access_token).and_return(true)
      call_endpoint
      expect(OAuthSession).to have_received(:revoke_for_access_token)
    end

    it 'responds with HTTP status ok' do
      call_endpoint
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /revoke (token_type_hint=refresh_token})' do
    let_it_be(:user) { create(:user) }
    let_it_be(:authorization_grant) { create(:authorization_grant, user:, redeemed: true) }
    let(:params) { { token:, token_type_hint: 'refresh_token' } }
    let(:token) { JsonWebToken.encode(attributes_for(:refresh_token, oauth_session:)) }
    let(:oauth_session) { create(:oauth_session, authorization_grant:) }

    include_context 'with an authenticated client', :post, :oauth_revoke_refresh_token_path

    it_behaves_like 'an endpoint that requires client authentication'

    it 'invokes the domain logic for revocation via generic lookup' do
      allow(OAuthSession).to receive(:revoke_for_refresh_token).and_return(true)
      call_endpoint
      expect(OAuthSession).to have_received(:revoke_for_refresh_token)
    end

    it 'responds with HTTP status ok' do
      call_endpoint
      expect(response).to have_http_status(:ok)
    end
  end
end
