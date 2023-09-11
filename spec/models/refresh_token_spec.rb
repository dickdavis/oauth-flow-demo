# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshToken do
  subject(:model) { build(:refresh_token, oauth_session:) }

  let(:oauth_session) { create(:oauth_session, authorization_grant:) }
  let(:authorization_grant) { create(:authorization_grant, user:) }
  let(:user) { create(:user) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:aud) }
    it { is_expected.not_to allow_value('http://foo.bar/api').for(:aud) }

    it { is_expected.to validate_presence_of(:exp) }
    it { is_expected.not_to allow_value(5.minutes.ago.to_i).for(:exp) }

    it { is_expected.to validate_presence_of(:iss) }
    it { is_expected.not_to allow_value('http://foo.bar/').for(:iss) }

    it { is_expected.to validate_presence_of(:jti) }
    it { is_expected.not_to allow_value('does-not-map-to-oauth-session').for(:jti) }

    it 'does not add any errors if all provided claims are valid' do
      expect(model).to be_valid
    end
  end

  describe 'callbacks' do
    describe '#revoke_oauth_session' do
      context 'when the `aud` claim is invalid' do
        it 'updates the OAuthSession status to `revoked`' do
          model.aud = ''
          expect do
            model.valid?
            oauth_session.reload
          end.to change(oauth_session, :status).from('created').to('revoked')
        end
      end

      context 'when the `iss` claim is invalid' do
        it 'updates the OAuthSession status to `revoked`' do
          model.iss = ''
          expect do
            model.valid?
            oauth_session.reload
          end.to change(oauth_session, :status).from('created').to('revoked')
        end
      end

      context 'when the `exp` claim is invalid' do
        it 'does not update the OAuthSession status to `revoked`' do
          model.exp = ''
          model.valid?
          expect(oauth_session.reload).not_to be_revoked_status
        end
      end

      context 'when the `jti` claim is invalid' do
        it 'does not update the OAuthSession status to `revoked`' do
          model.jti = ''
          model.valid?
          expect(oauth_session.reload).not_to be_revoked_status
        end
      end
    end

    describe '#expire_oauth_session' do
      context 'when the `exp` claim is blank' do
        it 'updates the OAuthSession status to `expired`' do
          model.exp = ''
          expect do
            model.valid?
            oauth_session.reload
          end.to change(oauth_session, :status).from('created').to('expired')
        end
      end

      context 'when the `exp` claim is expired' do
        it 'updates the OAuthSession status to `expired`' do
          model.exp = 5.minutes.ago.to_i
          expect do
            model.valid?
            oauth_session.reload
          end.to change(oauth_session, :status).from('created').to('expired')
        end
      end

      context 'when the `exp` is invalid and a revocable claim is also invalid' do
        it 'does not update the OAuthSession status to `expired`' do
          model.exp = ''
          model.aud = ''
          model.valid?
          expect(oauth_session.reload).not_to be_expired_status
        end

        it 'updates the OAuthSession status to `revoked`' do
          model.exp = ''
          model.aud = ''
          expect do
            model.valid?
            oauth_session.reload
          end.to change(oauth_session, :status).from('created').to('revoked')
        end
      end
    end
  end
end
