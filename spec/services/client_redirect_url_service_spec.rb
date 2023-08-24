# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientRedirectUrlService do
  describe '.call' do
    subject(:service_call) do
      described_class.new(client_id:, params:).call
    end

    let(:params) { { foo: 'oof', bar: 'rab' } }

    context 'with valid client config' do
      let(:client_id) { 'democlient' }

      it 'returns the redirect_url with params for the provided client' do
        expect(service_call.url).to eq('http://localhost:3000/?foo=oof&bar=rab')
      end
    end

    context 'with invalid client config' do
      let(:client_id) { 'invalidclient' }

      it 'raises an OAuth::InvalidRedirectUrlError' do
        expect { service_call }.to raise_error(OAuth::InvalidRedirectUrlError)
      end
    end
  end
end
