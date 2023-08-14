# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuthController do # rubocop:disable RSpec/FilePath
  describe 'GET /authorize' do
    subject(:call_endpoint) { get authorize_path }

    let(:state_token_encoder_service) { instance_double(StateTokenEncoderService, call: results) }
    let(:results) { StateTokenEncoderService::Response[status, body] }

    before do
      allow(StateTokenEncoderService).to receive(:new).and_return(state_token_encoder_service)
    end

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
