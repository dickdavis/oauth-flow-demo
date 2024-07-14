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
      context 'when client type is confidential' do
        it 'generates an API key when a new client is created' do
          expect { model.save! }.to change(model, :api_key).from(nil).to(be_present)
        end
      end

      context 'when client type is public' do
        it 'do not generate an API key when a new client is created' do
          model.client_type = 'public'
          expect { model.save! }.not_to change(model, :api_key).from(nil)
        end
      end
    end
  end

  describe '#new_authorization_grant' do
    subject(:call_method) { model.new_authorization_grant(user:, challenge_params:) }

    let(:user) { create(:user) }
    let(:challenge_params) { attributes_for(:oauth_challenge) }

    it 'returns an OAuth::AuthorizationGrant with appropriate values' do
      object = call_method
      aggregate_failures do
        expect(object).to be_a(OAuth::AuthorizationGrant)
        expect(object.oauth_client).to eq(model)
        expect(object.user).to eq(user)
        expect(object.oauth_challenge.code_challenge).to eq(challenge_params[:code_challenge])
        expect(object.oauth_challenge.code_challenge_method).to eq(challenge_params[:code_challenge_method])
        expect(object.oauth_challenge.client_redirection_uri).to eq(challenge_params[:client_redirection_uri])
      end
    end
  end

  describe '#new_authorization_request' do
    subject(:call_method) { model.new_authorization_request(**request_attrs.except(:oauth_client)) }

    let(:user) { create(:user) }
    let(:request_attrs) { attributes_for(:oauth_authorization_request, client_id: model.id, oauth_client: model) }

    it 'returns an OAuth::AuthorizationRequest with appropriate values' do
      object = call_method
      aggregate_failures do
        expect(object).to be_a(OAuth::AuthorizationRequest)
        expect(object.client_id).to eq(model.id)
        expect(object.code_challenge).to eq(request_attrs[:code_challenge])
        expect(object.code_challenge_method).to eq(request_attrs[:code_challenge_method])
        expect(object.redirect_uri).to eq(request_attrs[:redirect_uri])
        expect(object.response_type).to eq(request_attrs[:response_type])
        expect(object.state).to eq(request_attrs[:state])
      end
    end
  end

  describe '#url_for_redirect' do
    context 'with valid params' do
      let(:params) { { foo: 'bar' } }

      it 'returns the redirect_uri with the params' do
        expect(model.url_for_redirect(params:)).to eq('http://localhost:3000/?foo=bar')
      end
    end

    context 'with invalid params' do
      let(:params) { 'foobar' }

      it 'raises an OAuth::InvalidRedirectUrlError' do
        expect { model.url_for_redirect(params:) }.to raise_error(OAuth::InvalidRedirectUrlError)
      end
    end
  end
end
