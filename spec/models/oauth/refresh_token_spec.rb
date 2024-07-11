# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::RefreshToken do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_refresh_token, oauth_session:) }

  let_it_be(:user) { create(:user) }
  let_it_be(:oauth_authorization_grant) { create(:oauth_authorization_grant, user:) }
  let(:oauth_session) { create(:oauth_session, oauth_authorization_grant:) }

  it_behaves_like 'a model that validates token claims'
end
