# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe 'validations' do
    subject(:model) { build(:user) }

    it { is_expected.to have_secure_password }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_length_of(:first_name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_length_of(:last_name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value('test@test.com').for(:email) }
    it { is_expected.not_to allow_value('test@test').for(:email) }
    it { is_expected.not_to allow_value('testtest.com').for(:email) }
  end
end
