# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuthSession do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_session) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:access_token_jti) }
    it { is_expected.to validate_uniqueness_of(:access_token_jti) }
    it { is_expected.to allow_value(SecureRandom.uuid).for(:access_token_jti) }
    it { is_expected.not_to allow_value('foobar').for(:access_token_jti) }

    it { is_expected.to validate_presence_of(:refresh_token_jti) }
    it { is_expected.to validate_uniqueness_of(:refresh_token_jti) }
    it { is_expected.to allow_value(SecureRandom.uuid).for(:refresh_token_jti) }
    it { is_expected.not_to allow_value('foobar').for(:refresh_token_jti) }

    it { is_expected.to allow_value('created').for(:status) }
    it { is_expected.to allow_value('expired').for(:status) }
    it { is_expected.to allow_value('refreshed').for(:status) }
    it { is_expected.to allow_value('revoked').for(:status) }

    it 'raises an ArgumentError when an invalid status is provided' do
      expect { model.status = 'foobar' }.to raise_error(ArgumentError)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:authorization_grant) }
  end
end
