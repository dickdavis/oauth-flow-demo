# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController do
  describe 'DELETE /destroy' do
    subject(:call_endpoint) { delete sign_out_path }

    let(:user) { create(:user) }

    before do
      post authenticate_path, params: { email: user.email, password: 'password' }
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
