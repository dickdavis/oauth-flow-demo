# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationGrantsController do
  describe 'GET /new' do
    subject(:call_endpoint) { get new_authorization_grant_path, params: { state: } }

    let(:user) { create(:user) }
    let(:state) { JsonWebToken.encode({ client_id: 'democlient' }) }

    before do
      sign_in(user)
    end

    it_behaves_like 'an endpoint that requires user authentication'

    it 'renders a successful response' do
      call_endpoint
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /create' do
    subject(:call_endpoint) { post authorization_grants_path, params: { state:, approve: } }

    let(:user) { create(:user) }
    let(:approve) { 'true' }
    let(:state) { JsonWebToken.encode(payload) }
    let(:payload) do
      {
        client_id: 'democlient',
        client_state: 'foo',
        code_challenge: 'bar',
        code_challenge_method: 'S256'
      }
    end

    before do
      sign_in(user)
    end

    it_behaves_like 'an endpoint that requires user authentication'

    context 'when the resource owner rejects the authorization grant' do
      let(:approve) { 'false' }

      it 'redirects to client redirection_uri with state and error params' do
        call_endpoint
        expect(response).to redirect_to('http://localhost:3000/?error=access_denied&state=foo')
      end
    end

    context 'when the resource owner approves the authorization grant' do
      context 'when the authorization grant fails to create' do
        let(:authorization_grant_double) { instance_double(AuthorizationGrant, save: false) }

        before do
          allow(AuthorizationGrant).to receive(:new).and_return(authorization_grant_double)
        end

        it 'redirects to client redirection_uri with state and error params' do
          call_endpoint
          expect(response).to redirect_to('http://localhost:3000/?error=invalid_request&state=foo')
        end

        it 'does not create an authorization grant' do
          expect { call_endpoint }.not_to change(AuthorizationGrant, :count)
        end
      end

      context 'when the authorization grant is successfully created' do
        it 'redirects to client redirection_uri with state and code params' do
          call_endpoint
          expect(response).to redirect_to("http://localhost:3000/?code=#{AuthorizationGrant.last.id}&state=foo")
        end

        it 'creates an authorization grant' do
          expect { call_endpoint }.to change(AuthorizationGrant, :count)
        end
      end
    end
  end
end
