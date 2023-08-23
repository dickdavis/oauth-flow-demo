# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientRedirectUrlService do
  describe '.call' do
    subject(:service_call) do
      described_class.new(client_id:, params:).call
    end

    let(:client_id) { 'democlient' }
    let(:params) { { foo: 'oof', bar: 'rab' } }

    it 'returns the redirect_url with params for the provided client' do
      expect(service_call.url).to eq('http://localhost:3000/?foo=oof&bar=rab')
    end
  end
end
