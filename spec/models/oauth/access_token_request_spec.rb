# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AccessTokenRequest do # rubocop:disable RSpec/FilePath
  subject(:model) { described_class.new(**attrs) }

  let_it_be(:initial_attrs) { attributes_for(:oauth_access_token_request) }

  let(:attrs) do
    { code_verifier:, oauth_authorization_grant:, redirect_uri: }.compact
  end

  let(:code_verifier) { initial_attrs[:code_verifier] }
  let(:redirect_uri) { initial_attrs[:redirect_uri] }

  describe 'validations' do
    shared_examples 'validates oauth_authorization_grant is present' do
      it 'allows valid oauth_authorization_grant' do
        expect(model).to allow_value(oauth_authorization_grant).for(:oauth_authorization_grant)
      end

      it 'validates oauth_authorization_grant is present' do
        expect(model).not_to allow_value(nil).for(:oauth_authorization_grant)
      end

      it 'validates oauth_authorization_grant to map to a valid authorization grant' do
        expect(model).not_to allow_value('invalid-oauth-authorization-grant').for(:oauth_authorization_grant)
      end
    end

    shared_examples 'code_verifier is required' do
      it 'requires code_verifier param' do
        model.code_verifier = nil
        expect(model).not_to be_valid
      end
    end

    shared_examples 'code_verifier is not required' do
      it 'does not require code_verifier param' do
        model.code_verifier = nil
        expect(model).to be_valid
      end
    end

    shared_examples 'validates code_verifier matches code_challenge' do
      context 'when code_verifier is not valid' do
        it 'adds an error' do
          model.code_verifier = 'not-valid'
          expect(model).not_to be_valid
        end
      end

      context 'when code_verifier is valid' do
        it 'does not add an error' do
          model.code_verifier = 'code_verifier'
          expect(model).to be_valid
        end
      end
    end

    shared_examples 'redirect_uri is required' do
      it 'requires redirect_uri param' do
        model.redirect_uri = nil
        expect(model).not_to be_valid
      end
    end

    shared_examples 'redirect_uri is not required' do
      it 'does not require redirect_uri param' do
        model.redirect_uri = nil
        expect(model).to be_valid
      end
    end

    shared_examples 'validates redirect_uri param' do
      it 'validates redirect_uri param' do
        aggregate_failures do
          expect(model).to allow_value(oauth_client.redirect_uri).for(:redirect_uri)
          expect(model).not_to allow_value('invalid-redirect-uri').for(:redirect_uri)
        end
      end
    end

    context 'when no OAuth authorization grant is provided' do
      let(:oauth_authorization_grant) { nil }

      it 'adds an oauth_client error to the model and skips other validations' do
        aggregate_failures do
          expect(model).not_to be_valid
          expect(model.errors.count).to eq(1)
          expect(model.errors.first.attribute).to eq(:oauth_authorization_grant)
          expect(model.errors.first.type).to eq(:invalid)
        end
      end
    end

    context 'when OAuth client is public' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'public') }
      let(:oauth_authorization_grant) { create(:oauth_authorization_grant, oauth_client:) }

      let(:client_id) { oauth_client.id }

      it_behaves_like 'validates oauth_authorization_grant is present'
      it_behaves_like 'code_verifier is required'
      it_behaves_like 'validates code_verifier matches code_challenge'
      it_behaves_like 'redirect_uri is required'
      it_behaves_like 'validates redirect_uri param'
    end

    context 'when OAuth client is confidential' do
      let_it_be(:oauth_client) { create(:oauth_client, client_type: 'confidential') }

      let(:oauth_authorization_grant) do
        create(
          :oauth_authorization_grant,
          code_challenge:,
          code_challenge_method:,
          redirect_uri: challenge_redirect_uri,
          oauth_client:
        )
      end

      let(:code_verifier) { nil }
      let(:redirect_uri) { nil }
      let(:code_challenge) { nil }
      let(:code_challenge_method) { nil }
      let(:challenge_redirect_uri) { nil }

      it_behaves_like 'validates oauth_authorization_grant is present'
      it_behaves_like 'code_verifier is not required'
      it_behaves_like 'redirect_uri is not required'

      context 'when a code_verifier param is provided and code_challenge was provided in the authorization request' do
        let(:code_verifier) { 'code_verifier' }
        let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false) }
        let(:code_challenge_method) { 'S256' }

        it_behaves_like 'validates code_verifier matches code_challenge'
      end

      context 'when a code_verifier param is provided and code_challenge was not provided in authorization request' do
        let(:code_verifier) { 'code_verifier' }

        it 'adds an error' do
          expect(model).not_to be_valid
        end
      end

      context 'when redirect_uri is provided but not provided in authorization request' do
        let(:challenge_redirect_uri) { oauth_client.redirect_uri }

        it 'adds an error' do
          expect(model).not_to be_valid
        end
      end

      context 'when redirect_uri is provided in both the access token and authorization requests' do
        let(:redirect_uri) { oauth_client.redirect_uri }
        let(:challenge_redirect_uri) { oauth_client.redirect_uri }

        it_behaves_like 'validates redirect_uri param'
      end
    end
  end
end
