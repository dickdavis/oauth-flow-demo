# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuthSession do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_session) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_token_jti) }
    it { is_expected.to validate_uniqueness_of(:access_token_jti) }
    it { is_expected.to allow_value(SecureRandom.uuid).for(:access_token_jti) }
    it { is_expected.not_to allow_value('foobar').for(:access_token_jti) }

    it { is_expected.to validate_presence_of(:refresh_token_jti) }
    it { is_expected.to validate_uniqueness_of(:refresh_token_jti) }
    it { is_expected.to allow_value(SecureRandom.uuid).for(:refresh_token_jti) }
    it { is_expected.not_to allow_value('foobar').for(:refresh_token_jti) }

    it { is_expected.to allow_value('created').for(:status) }
    it { is_expected.to allow_value('expired').for(:status) }
    it { is_expected.to allow_value('refreshed').for(:status) }
    it { is_expected.to allow_value('revoked').for(:status) }

    it 'raises an ArgumentError when an invalid status is provided' do
      expect { model.status = 'foobar' }.to raise_error(ArgumentError)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:authorization_grant) }
  end

  describe '#refresh' do
    subject(:method_call) { oauth_session.refresh(token: refresh_token) }

    let!(:oauth_session) { create(:oauth_session, authorization_grant:) }
    let(:authorization_grant) { create(:authorization_grant, redeemed: true) }
    let(:refresh_token) { build(:refresh_token, oauth_session:) }

    it_behaves_like 'a model that creates OAuth sessions'

    context 'when the oauth session is in created status' do
      it 'updates the status attribute to refreshed' do
        expect { method_call }.to change(oauth_session, :status).from('created').to('refreshed')
      end

      it 'creates a new oauth session' do
        expect { method_call }.to change(described_class, :count).by(1)
      end
    end

    context 'when the provided token contains a JTI that does not match the refresh token JTI of the oauth session' do
      let(:refresh_token) { build(:refresh_token, oauth_session:, jti: 'foobar') }

      it 'raises an OAuth::ServerError' do
        expect { method_call }.to raise_error(OAuth::ServerError, I18n.t('oauth.mismatched_refresh_token_error'))
      end

      it 'does not create a new oauth session' do
        begin
          method_call
        rescue OAuth::ServerError
          nil
        end
        expect(described_class.count).to eq(1)
      end
    end

    context 'when the provided token has invalid claims' do
      let(:refresh_token) { build(:refresh_token, oauth_session:, exp: 14.days.ago.to_i) }

      it 'raises an OAuth::InvalidGrantError' do
        expect { method_call }.to raise_error(OAuth::InvalidGrantError)
      end

      it 'does not create a new oauth session' do
        begin
          method_call
        rescue OAuth::InvalidGrantError
          nil
        end
        expect(described_class.count).to eq(1)
      end
    end

    context 'when the oauth session has already been refreshed' do
      let!(:oauth_session) { create(:oauth_session, authorization_grant:, status: 'refreshed') }

      context 'with an active oauth session existing for authorization grant' do
        it 'revokes the active oauth session' do
          active_oauth_session = create(:oauth_session, authorization_grant:)
          expect do
            method_call
          rescue OAuth::RevokedSessionError
            active_oauth_session.reload
          end.to change(active_oauth_session, :status).from('created').to('revoked')
        end

        it 'raises an OAuth::RevokedSessionError' do
          create(:oauth_session, authorization_grant:)
          expect { method_call }.to raise_error(OAuth::RevokedSessionError)
        end

        it 'does not create a new oauth session' do
          create(:oauth_session, authorization_grant:)
          begin
            method_call
          rescue OAuth::RevokedSessionError
            nil
          end
          expect(described_class.count).to eq(2)
        end
      end

      context 'without an active oauth session existing for authorization grant' do
        it 'changes its own status to revoked' do
          expect do
            method_call
          rescue OAuth::RevokedSessionError
            nil
          end.to change(oauth_session, :status).from('refreshed').to('revoked')
        end

        it 'raises an OAuth::RevokedSessionError' do
          expect { method_call }.to raise_error(OAuth::RevokedSessionError)
        end

        it 'does not create a new oauth session' do
          begin
            method_call
          rescue OAuth::RevokedSessionError
            nil
          end
          expect(described_class.count).to eq(1)
        end
      end
    end

    context 'when the oauth session has already been revoked' do
      let!(:oauth_session) { create(:oauth_session, authorization_grant:, status: 'revoked') }

      context 'with an active oauth session existing for authorization grant' do
        it 'revokes the active oauth session' do
          active_oauth_session = create(:oauth_session, authorization_grant:)
          expect do
            method_call
          rescue OAuth::RevokedSessionError
            active_oauth_session.reload
          end.to change(active_oauth_session, :status).from('created').to('revoked')
        end

        it 'raises an OAuth::RevokedSessionError' do
          create(:oauth_session, authorization_grant:)
          expect { method_call }.to raise_error(OAuth::RevokedSessionError)
        end

        it 'does not create a new oauth session' do
          create(:oauth_session, authorization_grant:)
          begin
            method_call
          rescue OAuth::RevokedSessionError
            nil
          end
          expect(described_class.count).to eq(2)
        end
      end

      context 'without an active oauth session existing for authorization grant' do
        it 'keeps its own status as revoked' do
          begin
            method_call
          rescue OAuth::RevokedSessionError
            nil
          end
          expect(oauth_session.reload).to be_revoked_status
        end

        it 'raises an OAuth::RevokedSessionError' do
          expect { method_call }.to raise_error(OAuth::RevokedSessionError)
        end

        it 'does not create a new oauth session' do
          begin
            method_call
          rescue OAuth::RevokedSessionError
            nil
          end
          expect(described_class.count).to eq(1)
        end
      end
    end
  end

  describe 'revocation' do
    RSpec.shared_examples 'revokes self' do
      let(:oauth_session) { create(:oauth_session, authorization_grant:) }
      let(:authorization_grant) { create(:authorization_grant, redeemed: true) }

      before do
        # Set-up unrelated oauth sessions
        create(:oauth_session, authorization_grant: create(:authorization_grant, redeemed: true))
        create(:oauth_session, authorization_grant: create(:authorization_grant, redeemed: true))
        create(:oauth_session, authorization_grant: create(:authorization_grant, redeemed: true))
      end

      it 'revokes the oauth session' do
        expect do
          method_call
          oauth_session.reload
        end.to change(oauth_session, :status).from('created').to('revoked')
      end

      it 'does not revoke other oauth sessions' do
        method_call
        expect(described_class.where(status: 'revoked').count).to eq(1)
      end
    end

    RSpec.shared_examples 'revokes active oauth session' do
      let(:oauth_session) { create(:oauth_session, authorization_grant:) }
      let(:authorization_grant) { create(:authorization_grant, redeemed: true) }

      before do
        # Set-up unrelated oauth sessions
        create(:oauth_session, authorization_grant: create(:authorization_grant, redeemed: true))
        create(:oauth_session, authorization_grant: create(:authorization_grant, redeemed: true))
        create(:oauth_session, authorization_grant: create(:authorization_grant, redeemed: true))

        # Set-up a chain of oauth sessions related to an authorization grant
        create(:oauth_session, authorization_grant:, status: 'refreshed')
        create(:oauth_session, authorization_grant:, status: 'refreshed')
      end

      context 'when the oauth session is the active oauth session' do
        it 'revokes the oauth session' do
          expect do
            method_call
            oauth_session.reload
          end.to change(oauth_session, :status).from('created').to('revoked')
        end

        it 'does not revoke other oauth sessions' do
          method_call
          expect(described_class.where(status: 'revoked').count).to eq(1)
        end
      end

      context 'when the oauth session is not the active oauth session' do
        let(:oauth_session) { create(:oauth_session, authorization_grant:, status: 'refreshed') }

        it 'revokes the oauth session' do
          create(:oauth_session, authorization_grant:)
          expect do
            method_call
            oauth_session.reload
          end.to change(oauth_session, :status).from('refreshed').to('revoked')
        end

        it 'revokes the active oauth session for the authorization grant' do
          active_oauth_session = create(:oauth_session, authorization_grant:)
          expect do
            method_call
            active_oauth_session.reload
          end.to change(active_oauth_session, :status).from('created').to('revoked')
        end

        it 'does not revoke unrelated oauth sessions' do
          create(:oauth_session, authorization_grant:)
          method_call
          expect(described_class.where(status: 'revoked').count).to eq(2)
        end
      end
    end

    describe '#revoke_self_and_active_session' do
      let(:method_call) { oauth_session.revoke_self_and_active_session }

      it_behaves_like 'revokes self'
      it_behaves_like 'revokes active oauth session'
    end

    describe '.revoke_for_token' do
      subject(:method_call) { described_class.revoke_for_token(jti:) }

      let(:jti) { token.jti }

      context 'when provided an access token JTI' do
        let(:token) { build(:access_token, oauth_session:) }

        it_behaves_like 'revokes self'
        it_behaves_like 'revokes active oauth session'
      end

      context 'when provided a refresh token JTI' do
        let(:token) { build(:refresh_token, oauth_session:) }

        it_behaves_like 'revokes self'
        it_behaves_like 'revokes active oauth session'
      end
    end

    describe '.revoke_for_access_token' do
      subject(:method_call) { described_class.revoke_for_access_token(access_token_jti:) }

      let(:access_token_jti) { token.jti }

      let(:token) { build(:access_token, oauth_session:) }

      it_behaves_like 'revokes self'
      it_behaves_like 'revokes active oauth session'
    end

    describe '.revoke_for_refresh_token' do
      subject(:method_call) { described_class.revoke_for_refresh_token(refresh_token_jti:) }

      let(:refresh_token_jti) { token.jti }
      let(:token) { build(:refresh_token, oauth_session:) }

      it_behaves_like 'revokes self'
      it_behaves_like 'revokes active oauth session'
    end
  end
end
