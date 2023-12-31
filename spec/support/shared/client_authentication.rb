# frozen_string_literal: true

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
