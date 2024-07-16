# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AuthorizationsController do
  shared_examples 'handles an invalid request' do
    it 'redirects to the client redirect uri with the `invalid_request` error and state params' do
      call_endpoint
      redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
      aggregate_failures do
        expect(response.location).to match(oauth_client.redirect_uri)
        expect(redirect_params['error']).to eq('invalid_request')
        expect(redirect_params['state']).to eq(state)
      end
    end
  end

  shared_examples 'redirects successful authorize request' do
    it 'redirects the user to the authorization grant page with the state param' do
      call_endpoint
      redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
      aggregate_failures do
        expect(response.location).to match(new_oauth_authorization_grant_path)
        expect(redirect_params['state']).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
      end
    end
  end

  describe 'GET /authorize' do
    subject(:call_endpoint) { get oauth_authorize_path, params: }

    let(:params) do
      { client_id:, state:, code_challenge:, code_challenge_method:, redirect_uri:, response_type: }.compact
    end
    let(:client_id) { oauth_client.id }
    let(:state) { 'foobar' }
    let(:code_challenge) { 'code_challenge' }
    let(:code_challenge_method) { 'S256' }
    let(:redirect_uri) { oauth_client.redirect_uri }
    let(:response_type) { 'code' }

    context 'when the oauth client type is public' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'public') }

      context 'when the client_id param is missing' do
        let(:client_id) { nil }

        it 'responds with HTTP status unauthorized' do
          call_endpoint
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when an invalid code_challenge param is provided' do
        let(:code_challenge) { nil }

        it_behaves_like 'handles an invalid request'
      end

      context 'when an invalid code_challenge_method param is provided' do
        let(:code_challenge_method) { nil }

        it_behaves_like 'handles an invalid request'
      end

      context 'when an invalid redirect_uri param is provided' do
        let(:redirect_uri) { nil }

        it 'responds with HTTP status bad request' do
          call_endpoint
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'when an invalid response_type param is provided' do
        let(:response_type) { nil }

        it_behaves_like 'handles an invalid request'
      end

      context 'when authorization request is valid' do
        it_behaves_like 'redirects successful authorize request'
      end
    end

    context 'when the oauth client type is confidential' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'confidential') }

      include_context 'with an authenticated client', :get, :oauth_authorize_path

      it_behaves_like 'an endpoint that requires client authentication'

      context 'when the client_id param is missing' do
        let(:client_id) { nil }

        it 'does not respond with HTTP status unauthorized' do
          call_endpoint
          expect(response).not_to have_http_status(:unauthorized)
        end
      end

      context 'when an invalid code_challenge param is provided' do
        let(:code_challenge) { nil }

        it_behaves_like 'handles an invalid request'
      end

      context 'when an invalid code_challenge_method param is provided' do
        let(:code_challenge_method) { nil }

        it_behaves_like 'handles an invalid request'
      end

      context 'when an invalid redirect_uri param is provided' do
        let(:redirect_uri) { 'invalid' }

        it 'responds with HTTP status bad request' do
          call_endpoint
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'when an invalid response_type param is provided' do
        let(:response_type) { nil }

        it_behaves_like 'handles an invalid request'
      end

      context 'when authorization request is valid' do
        it_behaves_like 'redirects successful authorize request'
      end

      context 'when no redirect_uri param is provided' do
        let(:redirect_uri) { nil }

        it_behaves_like 'redirects successful authorize request'
      end

      context 'when no PKCE params are provided' do
        let(:code_challenge) { nil }
        let(:code_challenge_method) { nil }

        it_behaves_like 'redirects successful authorize request'
      end
    end
  end
end
