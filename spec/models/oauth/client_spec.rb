# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::Client do # rubocop:disable RSpec/FilePath
  subject(:model) { build(:oauth_client) }

  describe 'validations' do
    describe 'name' do
      it 'validates value is provided and within length constraints' do
        aggregate_failures do
          expect(model).to validate_presence_of(:name)
          expect(model).to validate_length_of(:name).is_at_least(3)
          expect(model).to validate_length_of(:name).is_at_most(255)
        end
      end
    end

    describe 'client_type' do
      it 'validates values for client_type' do
        aggregate_failures do
          expect(model).to allow_value('public').for(:client_type)
          expect(model).to allow_value('confidential').for(:client_type)
        end
      end

      it 'raises an ArgumentError when an invalid client_type is provided' do
        expect { model.client_type = 'foobar' }.to raise_error(ArgumentError)
      end
    end

    describe 'access_token_duration' do
      it 'validates value is an integer greater than 0' do
        aggregate_failures do
          expect(model).to validate_numericality_of(:access_token_duration).only_integer
          expect(model).to validate_numericality_of(:access_token_duration).is_greater_than(0)
        end
      end
    end

    describe 'refresh_token_duration' do
      it 'validates value is an integer greater than 0' do
        aggregate_failures do
          expect(model).to validate_numericality_of(:refresh_token_duration).only_integer
          expect(model).to validate_numericality_of(:refresh_token_duration).is_greater_than(0)
        end
      end
    end

    describe 'redirection_uri' do
      it { is_expected.to validate_presence_of(:redirect_uri) }

      it 'adds an error if redirect_uri is not a valid URI' do
        model.redirect_uri = 'foobar'
        model.valid?
        expect(model.errors).to include(:redirect_uri)
      end

      it 'does not add an error if redirect_uri is a valid URI' do
        model.redirect_uri = 'http://localhost:3000/'
        model.valid?
        expect(model.errors).not_to include(:redirect_uri)
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_api_key' do
      it 'generates an API key when a new client is created' do
        expect { model.save! }.to change(model, :api_key).from(nil).to(be_present)
      end
    end
  end
end
