# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshToken do
  subject(:model) { build(:refresh_token, oauth_session:) }

  let(:oauth_session) { create(:oauth_session, authorization_grant:) }
  let(:authorization_grant) { create(:authorization_grant, user:) }
  let(:user) { create(:user) }

  it_behaves_like 'a model that validates token claims'
end
