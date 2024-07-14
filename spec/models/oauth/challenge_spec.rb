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

  describe '#validate_code_challenge' do
    subject(:method_call) { model.validate_code_challenge(code_verifier:) }

    let(:code_verifier) { 'code_verifier' }

    context 'when valid code verifier is provided' do
      it 'does not add an error' do
        method_call
        expect(model.errors).to be_empty
      end
    end

    context 'when an empty code verifier is provided' do
      let(:code_verifier) { '' }

      it 'adds an error' do
        method_call
        expect(model.errors.where(:code_challenge)).to be_present
      end
    end

    context 'when invalid code verifier is provided' do
      let(:code_verifier) { 'invalid_code_verifier' }

      it 'adds an error' do
        method_call
        expect(model.errors.where(:code_challenge)).to be_present
      end
    end
  end

  describe '#validate_redirect_uri' do
    subject(:method_call) { model.validate_redirect_uri(redirection_uri:) }

    let(:redirection_uri) { model.redirect_uri }

    context 'when valid redirection_uri is provided' do
      it 'does not add an error' do
        method_call
        expect(model.errors).to be_empty
      end
    end

    context 'when redirection_uri does not match client redirect_uri' do
      let(:redirection_uri) { 'http://not-valid.uri/for/challenge' }

      it 'adds an error' do
        method_call
        expect(model.errors.where(:redirect_uri)).to be_present
      end
    end
  end
end
