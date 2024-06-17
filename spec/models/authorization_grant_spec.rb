# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationGrant do
  subject(:model) { build(:authorization_grant) }

  describe 'validations' do
    describe 'code_challenge' do
      it { is_expected.to validate_presence_of(:code_challenge) }
    end

    describe 'code_challenge_method' do
      it { is_expected.to validate_presence_of(:code_challenge_method) }
    end

    describe 'client_id' do
      it { is_expected.to validate_presence_of(:client_id) }

      it 'adds an error if client_id is not configured' do
        model.client_id = 'invalidclient'
        model.valid?
        expect(model.errors).to include(:client_id)
      end

      it 'does not add an error if client_id is configured' do
        model.client_id = 'democlient'
        model.valid?
        expect(model.errors).not_to include(:client_id)
      end
    end

    describe 'client_redirection_uri' do
      it { is_expected.to validate_presence_of(:client_redirection_uri) }

      it 'adds an error if client_redirection_uri does not match client configuration' do
        model.client_redirection_uri = 'http://not-configured.for/client'
        model.valid?
        expect(model.errors).to include(:client_redirection_uri)
      end

      it 'does not add an error if client_redirect_uri matches client configuration' do
        model.client_id = 'http://localhost:3000/'
        model.valid?
        expect(model.errors).not_to include(:client_redirection_uri)
      end
    end
  end

  describe 'associations' do
    specify(:aggregate_failures) do
      expect(model).to belong_to(:user)
      expect(model).to have_many(:oauth_sessions)
    end
  end

  describe '#active_oauth_session' do
    subject(:method_call) { authorization_grant.active_oauth_session }

    let_it_be(:authorization_grant) { create(:authorization_grant) }

    context 'when the authorization grant has an active oauth session' do
      it 'returns the active oauth session for the authorization grant' do
        _first_oauth_session = create(:oauth_session, authorization_grant:, status: 'refreshed')
        _second_oauth_session = create(:oauth_session, authorization_grant:, status: 'refreshed')
        third_oauth_session = create(:oauth_session, authorization_grant:)

        expect(method_call).to eq(third_oauth_session)
      end
    end

    context 'when the authorization grant does not have an active oauth session' do
      before do
        create_list(:oauth_session, 3, authorization_grant:, status: 'refreshed')
      end

      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end
  end

  describe '#redeem' do
    subject(:method_call) { authorization_grant.redeem(code_verifier:) }

    let(:code_verifier) { 'code_verifier' }

    context 'when the authorization grant has not been redeemed' do
      let_it_be(:authorization_grant) { create(:authorization_grant) }

      it_behaves_like 'a model that creates OAuth sessions'

      it 'updates the redeemed attribute' do
        expect { method_call }.to change(authorization_grant, :redeemed).from(false).to(true)
      end

      context 'when the code verifier does not match the code challenge for the authorization grant' do
        let(:code_verifier) { 'foobar' }

        it 'raises an OAuth::InvalidCodeVerifierError' do
          expect { method_call }.to raise_error(OAuth::InvalidCodeVerifierError)
        end
      end
    end

    context 'when the authorization grant has already been redeemed' do
      let(:authorization_grant) { create(:authorization_grant, redeemed: true) }

      it 'does not update the redeemed attribute' do
        expect { method_call }.not_to change(authorization_grant, :redeemed)
      end
    end
  end
end
