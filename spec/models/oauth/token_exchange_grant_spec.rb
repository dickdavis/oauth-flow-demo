# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::TokenExchangeGrant do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_token_exchange_grant) }

  describe 'associations' do
    specify(:aggregate_failures) do
      expect(model).to belong_to(:user)
      expect(model).to belong_to(:oauth_client)
      expect(model).to have_many(:oauth_sessions)
    end
  end
end
