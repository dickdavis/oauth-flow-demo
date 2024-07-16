# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::RefreshToken do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_refresh_token, oauth_session:) }

  let_it_be(:user) { create(:user) }
  let_it_be(:oauth_authorization_grant) { create(:oauth_authorization_grant, user:) }
  let(:oauth_session) { create(:oauth_session, oauth_authorization_grant:) }

  it_behaves_like 'a model that validates token claims'

  describe '.default' do
    let(:exp) { 1.hour.from_now.to_i }

    it 'returns a refresh token with default claims' do
      refresh_token = described_class.default(exp:)
      aggregate_failures do
        expect(refresh_token).to be_a(described_class)
        expect(refresh_token.aud).to eq(OAuth::CONFIG.audience_url)
        expect(refresh_token.exp).to eq(exp)
        expect(refresh_token.iat).to be_a(Integer)
        expect(refresh_token.iss).to eq(OAuth::CONFIG.issuer_url)
        expect(refresh_token.jti).to match(OAuth::Session::VALID_UUID_REGEX)
      end
    end
  end

  describe '.from_token' do
    let(:token) { JsonWebToken.encode(model.to_h) }

    it 'returns a model' do
      expect(described_class.from_token(token)).to be_a(described_class)
    end
  end

  describe '#to_h' do
    it 'returns the model attributes' do
      expect(model.to_h).to eq(
        {
          aud: model.aud,
          exp: model.exp,
          iat: model.iat,
          iss: model.iss,
          jti: model.jti
        }
      )
    end
  end

  describe '#to_encoded_token' do
    it 'returns the encoded token' do
      expect(model.to_encoded_token).to eq(JsonWebToken.encode(model.to_h, model.exp))
    end
  end
end
