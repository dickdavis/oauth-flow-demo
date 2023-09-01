# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationGrant do
  subject(:model) { build(:authorization_grant) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:code_challenge) }
    it { is_expected.to validate_presence_of(:code_challenge_method) }
    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_presence_of(:client_redirection_uri) }
    it { is_expected.to allow_value(5.minutes.from_now).for(:expires_at) }
    it { is_expected.not_to allow_value(10.minutes.from_now).for(:expires_at) }

    it 'adds an error if client_id is not configured' do
      model.client_id = 'invalidclient'
      model.save
      expect(model.errors).to include(:client_id)
    end

    it 'does not add an error if client_id is configured' do
      model.client_id = 'democlient'
      model.save
      expect(model.errors).not_to include(:client_id)
    end

    it 'adds an error if client_redirection_uri does not match client configuration' do
      model.client_redirection_uri = 'http://not-configured.for/client'
      model.save
      expect(model.errors).to include(:client_redirection_uri)
    end

    it 'does not add an error if client_redirect_uri matches client configuration' do
      model.client_id = 'http://localhost:3000/'
      model.save
      expect(model.errors).not_to include(:client_redirection_uri)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:oauth_sessions) }
  end
end
