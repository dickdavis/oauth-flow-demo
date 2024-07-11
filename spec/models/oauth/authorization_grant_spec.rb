# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AuthorizationGrant do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_authorization_grant) }

  describe 'associations' do
    specify(:aggregate_failures) do
      expect(model).to belong_to(:user)
      expect(model).to belong_to(:oauth_client)
      expect(model).to have_many(:oauth_sessions)
      expect(model).to have_one(:oauth_challenge).optional
    end
  end

  describe '#active_oauth_session' do
    subject(:method_call) { oauth_authorization_grant.active_oauth_session }

    let_it_be(:oauth_authorization_grant) { create(:oauth_authorization_grant) }

    context 'when the authorization grant has an active oauth session' do
      it 'returns the active oauth session for the authorization grant' do
        _first_oauth_session = create(:oauth_session, oauth_authorization_grant:, status: 'refreshed')
        _second_oauth_session = create(:oauth_session, oauth_authorization_grant:, status: 'refreshed')
        third_oauth_session = create(:oauth_session, oauth_authorization_grant:)

        expect(method_call).to eq(third_oauth_session)
      end
    end

    context 'when the authorization grant does not have an active oauth session' do
      before do
        create_list(:oauth_session, 3, oauth_authorization_grant:, status: 'refreshed')
      end

      it 'returns nil' do
        expect(method_call).to be_nil
      end
    end
  end

  shared_examples 'creates an OAuth session' do
    let(:oauth_authorization_grant) { create(:oauth_authorization_grant, oauth_client:) }
    let!(:oauth_challenge) { create(:oauth_challenge, oauth_authorization_grant:) } # rubocop:disable RSpec/LetSetup

    it_behaves_like 'a model that creates OAuth sessions'

    it 'updates the redeemed attribute and creates an OAuth session' do
      expect { method_call }.to change(oauth_authorization_grant, :redeemed).from(false).to(true)
                            .and change(OAuth::Session, :count).by(1)
    end
  end

  shared_examples 'validates the PKCE challenge' do
    let(:oauth_authorization_grant) { create(:oauth_authorization_grant, oauth_client:) }
    let!(:oauth_challenge) { create(:oauth_challenge, oauth_authorization_grant:) } # rubocop:disable RSpec/LetSetup
    let(:code_verifier) { 'foobar' }

    it 'raises an error' do
      expect { method_call }.to raise_error(OAuth::UnsuccessfulChallengeError)
    end

    it 'does not create an OAuth session' do
      expect do
        method_call
      rescue OAuth::UnsuccessfulChallengeError
        nil
      end.not_to change(OAuth::Session, :count)
    end
  end

  shared_examples 'validates the redirect_uri' do
    let(:oauth_authorization_grant) { create(:oauth_authorization_grant, oauth_client:) }
    let!(:oauth_challenge) do # rubocop:disable RSpec/LetSetup
      create(:oauth_challenge, client_redirection_uri: redirect_uri, oauth_authorization_grant:)
    end
    let(:redirect_uri) { 'not-a-valid-redirect-uri' }

    it 'raises an error' do
      expect { method_call }.to raise_error(OAuth::UnsuccessfulChallengeError)
    end

    it 'does not create an OAuth session' do
      expect do
        method_call
      rescue OAuth::UnsuccessfulChallengeError
        nil
      end.not_to change(OAuth::Session, :count)
    end
  end

  shared_examples 'does not create sessions for authorizations grants that have been redeemed' do
    let(:oauth_authorization_grant) { create(:oauth_authorization_grant, oauth_client:, redeemed: true) }
    let!(:oauth_challenge) { create(:oauth_challenge, oauth_authorization_grant:) } # rubocop:disable RSpec/LetSetup

    it 'raises an error' do
      expect { method_call }.to raise_error(OAuth::InvalidGrantError)
    end

    it 'does not create an OAuth session' do
      expect do
        method_call
      rescue OAuth::InvalidGrantError
        nil
      end.not_to change(OAuth::Session, :count)
    end
  end

  describe '#redeem' do
    subject(:method_call) { oauth_authorization_grant.redeem(**options.compact) }

    let(:options) { { code_verifier:, redirection_uri: } }
    let(:code_verifier) { 'code_verifier' }
    let(:redirection_uri) { oauth_client.redirect_uri }

    context 'when the oauth client has a public client type' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'public') }

      it_behaves_like 'creates an OAuth session'
      it_behaves_like 'validates the PKCE challenge'
      it_behaves_like 'validates the redirect_uri'
      it_behaves_like 'does not create sessions for authorizations grants that have been redeemed'
    end

    context 'when the oauth client has a confidential client type' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'confidential') }

      it_behaves_like 'creates an OAuth session'
      it_behaves_like 'validates the PKCE challenge'
      it_behaves_like 'validates the redirect_uri'
      it_behaves_like 'does not create sessions for authorizations grants that have been redeemed'
    end
  end
end
