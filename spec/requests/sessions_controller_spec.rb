# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController do
  describe 'POST /create' do
    subject(:call_endpoint) { post sign_in_path, params: }

    let(:user) { create(:user) }

    context 'with valid parameters' do
      let(:params) { { email: user.email, password: 'password' } }

      it 'adds the user ID to the session' do
        call_endpoint
        expect(controller.session[:user_id]).to eq(user.id.to_s)
      end

      it 'redirects to the home page' do
        call_endpoint
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with missing email' do
      let(:params) { { email: nil, password: 'password' } }

      it 'does not add the user ID to the session' do
        call_endpoint
        expect(controller.session[:user_id]).to be_nil
      end

      it 'does not redirect to the home page' do
        call_endpoint
        expect(response).not_to redirect_to(root_path)
      end
    end

    context 'with missing password' do
      let(:params) { { email: user.email, password: nil } }

      it 'does not add the user ID to the session' do
        call_endpoint
        expect(controller.session[:user_id]).to be_nil
      end

      it 'does not redirect to the home page' do
        call_endpoint
        expect(response).not_to redirect_to(root_path)
      end
    end

    context 'with wrong password' do
      let(:params) { { email: user.email, password: 'invalidpassword' } }

      it 'does not add the user ID to the session' do
        call_endpoint
        expect(controller.session[:user_id]).to be_nil
      end

      it 'does not redirect to the home page' do
        call_endpoint
        expect(response).not_to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /destroy' do
    subject(:call_endpoint) { delete sign_out_path }

    let(:user) { create(:user) }

    before do
      post sign_in_path, params: { email: user.email, password: 'password' }
    end

    it 'deletes the user_id from the session' do
      call_endpoint
      expect(controller.session[:user_id]).to be_nil
    end

    it 'redirects to the root path' do
      call_endpoint
      expect(response).to redirect_to(root_path)
    end
  end
end
