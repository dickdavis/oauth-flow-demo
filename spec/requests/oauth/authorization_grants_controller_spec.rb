# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AuthorizationGrantsController do
  describe 'GET /new' do
    subject(:call_endpoint) { get new_oauth_authorization_grant_path, params: { state: } }

    let_it_be(:user) { create(:user) }
    let(:state) { JsonWebToken.encode({ client_id: oauth_client.id }) }

    before_all do
      sign_in(user)
    end

    context 'when the oauth client type is public' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'public') }

      it 'renders a successful response' do
        call_endpoint
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the oauth client type is confidential' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'public') }

      it_behaves_like 'an endpoint that requires user authentication'

      it 'renders a successful response' do
        call_endpoint
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /create' do
    subject(:call_endpoint) { post oauth_authorization_grants_path, params: { state:, approve: } }

    let_it_be(:user) { create(:user) }
    let(:approve) { 'true' }
    let(:state) do
      JsonWebToken.encode(
        {
          client_id: oauth_client.id,
          client_state: 'foo',
          code_challenge: 'bar',
          code_challenge_method: 'S256',
          redirect_uri: oauth_client.redirect_uri
        }
      )
    end

    before_all do
      sign_in(user)
    end

    context 'when the oauth client type is public' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'public') }

      context 'when the resource owner approves the authorization grant' do
        context 'when the authorization grant is successfully created' do
          it 'creates an authorization grant and redirects to client redirection_uri with state and code params' do
            aggregate_failures do
              expect { call_endpoint }.to change(OAuth::AuthorizationGrant, :count)
              expect(response).to redirect_to("http://localhost:3000/?code=#{OAuth::AuthorizationGrant.last.id}&state=foo")
            end
          end
        end

        context 'when the authorization grant fails to create' do
          before do
            allow_any_instance_of(OAuth::AuthorizationGrant).to receive(:save!).and_raise(ActiveRecord::RecordInvalid) # rubocop:disable RSpec/AnyInstance
          end

          it 'redirects to client redirection_uri with state and error params' do
            call_endpoint
            expect(response).to redirect_to('http://localhost:3000/?error=invalid_request&state=foo')
          end
        end
      end

      context 'when the resource owner rejects the authorization grant' do
        let(:approve) { 'false' }

        it 'redirects to client redirection_uri with state and error params' do
          call_endpoint
          expect(response).to redirect_to('http://localhost:3000/?error=access_denied&state=foo')
        end
      end
    end

    context 'when the oauth client type is confidential' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'confidential') }

      it_behaves_like 'an endpoint that requires user authentication'
    end
  end
end
