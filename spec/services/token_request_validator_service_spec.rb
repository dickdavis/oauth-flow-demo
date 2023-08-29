# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TokenRequestValidatorService do
  describe '.call' do
    subject(:service_call) do
      described_class.new(authorization_grant:, code_verifier:, grant_type:).call
    end

    let(:authorization_grant) { create(:authorization_grant) }
    let(:code_verifier) { 'code_verifier' }
    let(:grant_type) { 'authorization_code' }

    context 'when the code is not a valid authorization code' do
      let(:authorization_grant) { nil }

      it 'returns false' do
        expect(service_call).to be_falsey
      end
    end

    context 'when the code is has already been redeemed' do
      let(:authorization_grant) { create(:authorization_grant, redeemed: true) }

      it 'returns false' do
        expect(service_call).to be_falsey
      end
    end

    context 'when the code verifier does not match the code challenge for the authorization grant' do
      let(:code_verifier) { 'foobar' }

      it 'returns false' do
        expect(service_call).to be_falsey
      end
    end

    context 'when the grant_type is not authorization_code' do
      let(:grant_type) { 'foobar' }

      it 'returns false' do
        expect(service_call).to be_falsey
      end
    end

    context 'when provided params are valid' do
      it 'returns true' do
        expect(service_call).to be_truthy
      end
    end
  end

  describe '.call!' do
    subject(:service_call) do
      described_class.new(authorization_grant:, code_verifier:, grant_type:).call!
    end

    let(:authorization_grant) { create(:authorization_grant) }
    let(:code_verifier) { 'code_verifier' }
    let(:grant_type) { 'authorization_code' }

    context 'when the code is not a valid authorization code' do
      let(:authorization_grant) { nil }

      it 'raises an OAuth::UnsupportedGrantTypeError' do
        expect { service_call }.to raise_error(OAuth::InvalidGrantError)
      end
    end

    context 'when the code is has already been redeemed' do
      let(:authorization_grant) { create(:authorization_grant, redeemed: true) }

      it 'raises an OAuth::UnsupportedGrantTypeError' do
        expect { service_call }.to raise_error(OAuth::InvalidGrantError)
      end
    end

    context 'when the code verifier does not match the code challenge for the authorization grant' do
      let(:code_verifier) { 'foobar' }

      it 'raises an OAuth::InvalidRequestError' do
        expect { service_call }.to raise_error(OAuth::InvalidRequestError)
      end
    end

    context 'when the grant_type is not authorization_code' do
      let(:grant_type) { 'foobar' }

      it 'raises an OAuth::UnsupportedGrantTypeError' do
        expect { service_call }.to raise_error(OAuth::UnsupportedGrantTypeError)
      end
    end

    context 'when provided params are valid' do
      it 'returns true' do
        expect(service_call).to be_truthy
      end
    end
  end
end
