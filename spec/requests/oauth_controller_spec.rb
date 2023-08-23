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
  context 'without client_id param' do
    let(:shared_context_params) { super().except(:client_id) }

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
    let(:state_token_encoder_service) { instance_double(StateTokenEncoderService, call: results) }
    let(:results) { StateTokenEncoderService::Response[status, body] }

    before do
      allow(StateTokenEncoderService).to receive(:new).and_return(state_token_encoder_service)
    end

    include_context 'with an authenticated client', :get, :authorize_path

    it_behaves_like 'an endpoint that requires client authentication'

    context 'when state token encoder service returns bad request status' do
      let(:status) { :bad_request }
      let(:body) { { errors: 'foobar' } }

      it 'returns http status bad request' do
        call_endpoint
        expect(response).to have_http_status(:bad_request)
      end

      it 'returns a JSON response with the error message' do
        call_endpoint
        expect(response.parsed_body).to eq(body.as_json)
      end
    end

    context 'when state token encoder service returns ok status' do
      let(:status) { :ok }
      let(:body) { 'state token' }

      it 'returns HTTP status ok' do
        call_endpoint
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
