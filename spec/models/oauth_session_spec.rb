# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuthSession do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_session) }

  describe 'validations' do
    describe 'access_token_jti' do
      it { is_expected.to validate_presence_of(:access_token_jti) }

      it 'validates values for access_token_jti' do
        aggregate_failures do
          expect(model).to validate_uniqueness_of(:access_token_jti)
          expect(model).to allow_value(SecureRandom.uuid).for(:access_token_jti)
          expect(model).not_to allow_value('foobar').for(:access_token_jti)
        end
      end
    end

    describe 'refresh_token_jti' do
      it { is_expected.to validate_presence_of(:refresh_token_jti) }

      it 'validates values for refresh_token_jti' do
        aggregate_failures do
          expect(model).to validate_uniqueness_of(:refresh_token_jti)
          expect(model).to allow_value(SecureRandom.uuid).for(:refresh_token_jti)
          expect(model).not_to allow_value('foobar').for(:refresh_token_jti)
        end
      end
    end

    describe 'status' do
      it 'validates values for status' do
        aggregate_failures do
          expect(model).to allow_value('created').for(:status)
          expect(model).to allow_value('expired').for(:status)
          expect(model).to allow_value('refreshed').for(:status)
          expect(model).to allow_value('revoked').for(:status)
        end
      end

      it 'raises an ArgumentError when an invalid status is provided' do
        expect { model.status = 'foobar' }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:authorization_grant) }
  end

  describe '#refresh' do
    subject(:method_call) { oauth_session.refresh(token: refresh_token) }

    let_it_be(:authorization_grant) { create(:authorization_grant, redeemed: true) }
    let!(:oauth_session) { create(:oauth_session, authorization_grant:) }
    let(:refresh_token) { build(:refresh_token, oauth_session:) }

    it_behaves_like 'a model that creates OAuth sessions'

    context 'when the OAuth session is in created status' do
      it 'refreshes the OAuth session' do
        aggregate_failures do
          expect { method_call }.to change(oauth_session, :status).from('created').to('refreshed')
          expect(described_class.count).to eq(2)
        end
      end
    end

    context 'when the provided token contains a JTI that does not match the refresh token JTI of the OAuth session' do
      let(:refresh_token) { build(:refresh_token, oauth_session:, jti: 'foobar') }

      it 'does not refresh the OAuth session and raises an OAuth::ServerError' do
        aggregate_failures do
          expect { method_call }.to raise_error(OAuth::ServerError, I18n.t('oauth.mismatched_refresh_token_error'))
          expect(described_class.count).to eq(1)
        end
      end
    end

    context 'when the provided token has invalid claims' do
      let(:refresh_token) { build(:refresh_token, oauth_session:, exp: 14.days.ago.to_i) }

      it 'does not refresh the session and raises an OAuth::InvalidGrantError' do
        aggregate_failures do
          expect { method_call }.to raise_error(OAuth::InvalidGrantError)
          expect(described_class.count).to eq(1)
        end
      end
    end

    context 'when the OAuth session has already been refreshed' do
      let_it_be(:oauth_session) { create(:oauth_session, authorization_grant:, status: 'refreshed') }

      context 'with an active OAuth session existing for authorization grant' do
        it 'revokes the OAuth session and raises an OAuth::RevokedSessionError' do
          active_oauth_session = create(:oauth_session, authorization_grant:)
          aggregate_failures do
            expect { method_call }.to raise_error(OAuth::RevokedSessionError)
            expect(active_oauth_session.reload).to be_revoked_status
            expect(described_class.count).to eq(2)
          end
        end
      end

      context 'without an active OAuth session existing for authorization grant' do
        it 'does not refresh the OAuth session and raises an OAuth::RevokedSessionError' do
          aggregate_failures do
            expect { method_call }.to raise_error(OAuth::RevokedSessionError)
            expect(oauth_session.reload).to be_revoked_status
            expect(described_class.count).to eq(1)
          end
        end
      end
    end

    context 'when the OAuth session has already been revoked' do
      let_it_be(:oauth_session) { create(:oauth_session, authorization_grant:, status: 'revoked') }

      context 'with an active OAuth session existing for authorization grant' do
        it 'revokes the active OAuth session and raises an OAuth::RevokedSessionError' do
          active_oauth_session = create(:oauth_session, authorization_grant:)
          aggregate_failures do
            expect { method_call }.to raise_error(OAuth::RevokedSessionError)
            expect(active_oauth_session.reload).to be_revoked_status
            expect(oauth_session.reload).to be_revoked_status
            expect(described_class.count).to eq(2)
          end
        end
      end

      context 'without an active OAuth session existing for authorization grant' do
        it 'does not refresh the OAuth session and raises an OAuth::RevokedSessionError' do
          aggregate_failures do
            expect { method_call }.to raise_error(OAuth::RevokedSessionError)
            expect(oauth_session.reload).to be_revoked_status
            expect(described_class.count).to eq(1)
          end
        end
      end
    end
  end

  describe 'revocation' do
    RSpec.shared_examples 'a revocable OAuth session' do
      let_it_be(:authorization_grant) { create(:authorization_grant, redeemed: true) }

      context 'when the OAuth session is the active OAuth session' do
        let(:oauth_session) { create(:oauth_session, authorization_grant:) }

        it 'only revokes the active OAuth session' do
          other_oauth_session = create(:oauth_session, authorization_grant:, status: 'refreshed')
          aggregate_failures do
            expect do
              method_call
              oauth_session.reload
            end.to change(oauth_session, :status).from('created').to('revoked')
            expect(other_oauth_session.reload.status).to eq('refreshed')
            expect(described_class.where(status: 'revoked').count).to eq(1)
          end
        end
      end

      context 'when the OAuth session is not the active OAuth session' do
        let(:oauth_session) { create(:oauth_session, authorization_grant:, status: 'refreshed') }

        it 'only revokes all related OAuth sessions for the authorization grant' do
          active_oauth_session = create(:oauth_session, authorization_grant:)
          alt_oauth_session = create(:oauth_session, authorization_grant: create(:authorization_grant, redeemed: true))
          aggregate_failures do
            expect do
              method_call
              active_oauth_session.reload
            end.to change(active_oauth_session, :status).from('created').to('revoked')
            expect(alt_oauth_session.reload.status).to eq('created')
            expect(described_class.where(status: 'revoked').count).to eq(2)
          end
        end
      end
    end

    describe '#revoke_self_and_active_session' do
      let(:method_call) { oauth_session.revoke_self_and_active_session }

      it_behaves_like 'a revocable OAuth session'
    end

    describe '.revoke_for_token' do
      subject(:method_call) { described_class.revoke_for_token(jti:) }

      let(:jti) { token.jti }

      context 'when provided an access token JTI' do
        let(:token) { build(:access_token, oauth_session:) }

        it_behaves_like 'a revocable OAuth session'
      end

      context 'when provided a refresh token JTI' do
        let(:token) { build(:refresh_token, oauth_session:) }

        it_behaves_like 'a revocable OAuth session'
      end
    end

    describe '.revoke_for_access_token' do
      subject(:method_call) { described_class.revoke_for_access_token(access_token_jti:) }

      let(:access_token_jti) { token.jti }
      let(:token) { build(:access_token, oauth_session:) }

      it_behaves_like 'a revocable OAuth session'
    end

    describe '.revoke_for_refresh_token' do
      subject(:method_call) { described_class.revoke_for_refresh_token(refresh_token_jti:) }

      let(:refresh_token_jti) { token.jti }
      let(:token) { build(:refresh_token, oauth_session:) }

      it_behaves_like 'a revocable OAuth session'
    end
  end
end
