# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UsersController do
  describe 'GET /new' do
    subject(:call_endpoint) { get new_user_path }

    it 'renders a successful response' do
      call_endpoint
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    subject(:call_endpoint) { post users_path, params: { user: attributes } }

    context 'with valid parameters' do
      let(:attributes) do
        attributes_for(:user)
          .except(:password_digest)
          .merge({ password: 'password', password_confirmation: 'password' })
      end

      it 'creates a new user' do
        expect do
          call_endpoint
        end.to change(User, :count).by(1)
      end

      it 'redirects to the home page' do
        call_endpoint
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid parameters' do
      let(:attributes) do
        attributes_for(:user, first_name: '')
          .except(:password_digest)
          .merge({ password: 'password', password_confirmation: 'password' })
      end

      it 'does not create a new user' do
        expect do
          call_endpoint
        end.not_to change(User, :count)
      end

      it "renders a response with 422 status (i.e. to display the 'new' template)" do
        call_endpoint
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
