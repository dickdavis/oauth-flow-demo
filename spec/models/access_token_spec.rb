# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessToken do
  subject(:model) { build(:access_token, oauth_session:) }

  let_it_be(:user) { create(:user) }
  let_it_be(:authorization_grant) { create(:authorization_grant, user:) }
  let(:oauth_session) { create(:oauth_session, authorization_grant:) }

  it_behaves_like 'a model that validates token claims'

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }

    it 'adds an error if the provided `user_id` claim does not map to the original authorization grant' do
      other_user = create(:user)
      model.user_id = other_user.id
      model.valid?
      expect(model.errors).to include(:user_id)
    end
  end

  describe 'callbacks' do
    describe '#revoke_oauth_session' do
      context 'when the `user_id` claim is invalid' do
        it 'updates the OAuthSession status to `revoked`' do
          model.user_id = ''
          expect do
            model.valid?
            oauth_session.reload
          end.to change(oauth_session, :status).from('created').to('revoked')
        end
      end
    end
  end
end
