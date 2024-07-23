# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::Challenge do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_challenge, oauth_authorization_grant:) }

  let_it_be(:oauth_client) { create(:oauth_client) }
  let_it_be(:oauth_authorization_grant) { create(:oauth_authorization_grant, oauth_client:) }

  describe 'validations' do
    describe 'code_challenge_method' do
      it do
        aggregate_failures do
          expect(model).to validate_inclusion_of(:code_challenge_method)
                       .in_array(OAuth::Challenge::VALID_CODE_CHALLENGE_METHODS)
          expect(model).to allow_value(nil).for(:code_challenge_method)
        end
      end
    end
  end

  describe 'associations' do
    specify(:aggregate_failures) do
      expect(model).to belong_to(:oauth_authorization_grant)
    end
  end
end
