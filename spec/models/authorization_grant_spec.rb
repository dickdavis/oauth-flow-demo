# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationGrant do
  subject(:model) { build(:authorization_grant) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:code_challenge) }
    it { is_expected.to validate_presence_of(:code_challenge_method) }
    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_presence_of(:client_redirection_uri) }
    it { is_expected.to allow_value(5.minutes.from_now).for(:expires_at) }
    it { is_expected.not_to allow_value(10.minutes.from_now).for(:expires_at) }

    it 'adds an error if client_id is not configured' do
      model.client_id = 'invalidclient'
      model.save
      expect(model.errors).to include(:client_id)
    end

    it 'does not add an error if client_id is configured' do
      model.client_id = 'democlient'
      model.save
      expect(model.errors).not_to include(:client_id)
    end

    it 'adds an error if client_redirection_uri does not match client configuration' do
      model.client_redirection_uri = 'http://not-configured.for/client'
      model.save
      expect(model.errors).to include(:client_redirection_uri)
    end

    it 'does not add an error if client_redirect_uri matches client configuration' do
      model.client_id = 'http://localhost:3000/'
      model.save
      expect(model.errors).not_to include(:client_redirection_uri)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:oauth_sessions) }
  end

  describe '#active_oauth_session' do
    subject(:active_oauth_session) { authorization_grant.active_oauth_session }

    let(:authorization_grant) { create(:authorization_grant) }

    context 'when the authorization grant has an active oauth session' do
      it 'returns the active oauth session for the authorization grant' do
        _first_oauth_session = create(:oauth_session, authorization_grant:, status: 'refreshed')
        _second_oauth_session = create(:oauth_session, authorization_grant:, status: 'refreshed')
        third_oauth_session = create(:oauth_session, authorization_grant:)

        expect(active_oauth_session).to eq(third_oauth_session)
      end
    end

    context 'when the authorization grant does not have an active oauth session' do
      before do
        create_list(:oauth_session, 3, authorization_grant:, status: 'refreshed')
      end

      it 'returns nil' do
        expect(active_oauth_session).to be_nil
      end
    end
  end

  describe '#redeem' do
    subject(:method_call) { authorization_grant.redeem }

    let(:authorization_grant) { create(:authorization_grant) }

    it_behaves_like 'a model that creates OAuth sessions'

    context 'when the authorization grant has not been redeemed' do
      it 'updates the redeemed attribute' do
        expect { method_call }.to change(authorization_grant, :redeemed).from(false).to(true)
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
