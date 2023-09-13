# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserBlueprint do
  describe '.render' do
    subject(:serialized_data) { described_class.render(user) }

    let(:user) { create(:user) }

    it 'renders the fields' do
      expect(JSON.parse(serialized_data)).to eq(
        {
          'first_name' => user.first_name,
          'last_name' => user.last_name,
          'email' => user.email
        }
      )
    end
  end
end
