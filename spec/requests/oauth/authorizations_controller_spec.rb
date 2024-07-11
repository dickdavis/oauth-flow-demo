# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AuthorizationsController do
  describe 'GET /authorize' do
    context 'when the oauth client type is public' do
      subject(:call_endpoint) { get oauth_authorize_path, params: }

      let(:params) { { client_id:, state:, code_challenge:, code_challenge_method:, response_type: } }
      let(:client_id) { oauth_client.id }
      let(:state) { 'foobar' }
      let(:code_challenge) { 'code_challenge' }
      let(:code_challenge_method) { 'S256' }
      let(:response_type) { 'code' }

      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'public') }

      context 'when the client_id param is missing' do
        let(:client_id) { nil }

        it 'responds with HTTP status unauthorized' do
          call_endpoint
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when an invalid param is provided' do
        let(:code_challenge_method) { nil }

        it 'redirects to the client redirect uri with the correct params' do
          call_endpoint
          redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          aggregate_failures do
            expect(response.location).to match(oauth_client.redirect_uri)
            expect(redirect_params['error']).to eq('invalid_request')
            expect(redirect_params['state']).to eq(state)
          end
        end

        context 'when the client redirect url generation raises an error' do
          it 'responds with HTTP status bad request' do
            allow_any_instance_of(OAuth::Client).to receive(:url_for_redirect).and_raise(OAuth::InvalidRedirectUrlError) # rubocop:disable RSpec/AnyInstance
            call_endpoint
            expect(response).to have_http_status(:bad_request)
          end
        end
      end

      context 'when the internal state token is generated successfully' do
        it 'redirects the user to the authorization grant page with the state param' do
          call_endpoint
          redirect_params = Rack::Utils.parse_query(URI.parse(response.location).query)
          aggregate_failures do
            expect(response.location).to match(new_oauth_authorization_grant_path)
            expect(redirect_params['state']).to match(/\A[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+\z/)
          end
        end
      end
    end

    context 'when the oauth client type is confidential' do
      let(:params) { { client_id:, state:, code_challenge:, code_challenge_method:, response_type: }.compact }
      let(:client_id) { nil }
      let(:state) { 'foobar' }
      let(:code_challenge) { 'code_challenge' }
      let(:code_challenge_method) { 'S256' }
      let(:response_type) { 'code' }

      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'confidential') }

      include_context 'with an authenticated client', :get, :oauth_authorize_path

      it_behaves_like 'an endpoint that requires client authentication'
    end
  end
end
