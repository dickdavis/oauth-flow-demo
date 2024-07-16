# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  subject(:model) { build(:user) }

  describe 'validations' do
    specify(:aggregate_failures) do
      expect(model).to have_secure_password
    end

    describe 'email' do
      specify(:aggregate_failures) do
        expect(model).to validate_presence_of(:email)
        expect(model).to validate_uniqueness_of(:email).case_insensitive
        expect(model).to allow_value('test@test.com').for(:email)
        expect(model).not_to allow_value('test@test').for(:email)
        expect(model).not_to allow_value('testtest.com').for(:email)
        expect(model).to validate_length_of(:email).is_at_most(255)
      end
    end

    describe 'first_name' do
      specify(:aggregate_failures) do
        expect(model).to validate_presence_of(:first_name)
        expect(model).to validate_length_of(:first_name).is_at_most(255)
      end
    end

    describe 'last_name' do
      specify(:aggregate_failures) do
        expect(model).to validate_presence_of(:last_name)
        expect(model).to validate_length_of(:last_name).is_at_most(255)
      end
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:oauth_authorization_grants) }
  end
end
