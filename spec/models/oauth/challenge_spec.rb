# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::Challenge do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_challenge, oauth_authorization_grant:) }

  let_it_be(:oauth_client) { create(:oauth_client) }
  let_it_be(:oauth_authorization_grant) { create(:oauth_authorization_grant, oauth_client:) }

  describe 'validations' do
    describe 'code_challenge_method' do
      it do
        aggregate_failures do
          expect(model).to validate_inclusion_of(:code_challenge_method)
                       .in_array(OAuth::Challenge::VALID_CODE_CHALLENGE_METHODS)
          expect(model).to allow_value(nil).for(:code_challenge_method)
        end
      end
    end
  end

  describe 'associations' do
    specify(:aggregate_failures) do
      expect(model).to belong_to(:oauth_authorization_grant)
    end
  end

  describe '#validate_code_verifier!' do
    subject(:method_call) { model.validate_code_verifier!(code_verifier:) }

    let(:code_verifier) { 'code_verifier' }

    context 'when valid code verifier is provided' do
      it 'does not raise an error' do
        expect { method_call }.not_to raise_error
      end
    end

    context 'when an empty code verifier is provided' do
      let(:code_verifier) { '' }

      it 'raises an error' do
        expect { method_call }.to raise_error(OAuth::InvalidCodeVerifierError)
      end
    end

    context 'when invalid code verifier is provided' do
      let(:code_verifier) { 'invalid_code_verifier' }

      it 'raises an error' do
        expect { method_call }.to raise_error(OAuth::InvalidCodeVerifierError)
      end
    end
  end

  describe '#validate_redirection_uri!' do
    subject(:method_call) { model.validate_redirection_uri!(redirection_uri:) }

    let(:redirection_uri) { model.client_redirection_uri }

    context 'when valid redirection_uri is provided' do
      it 'does not raise an error' do
        expect { method_call }.not_to raise_error
      end
    end

    context 'when redirection_uri does not match client_redirection_uri' do
      let(:redirection_uri) { 'http://not-valid.uri/for/challenge' }

      it 'raises an error' do
        expect { method_call }.to raise_error(OAuth::InvalidRedirectionURIError)
      end
    end
  end
end
