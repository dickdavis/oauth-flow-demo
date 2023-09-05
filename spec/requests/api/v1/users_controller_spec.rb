# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::V1::UsersController do
  describe 'GET /current' do
    let(:params) { {} }
    let(:headers) { {} }
    let(:user) { create(:user) }

    include_context 'with a valid access token', :get, :api_v1_current_user_path

    it_behaves_like 'an endpoint that requires token authentication'

    it 'renders a successful response' do
      call_endpoint
      expect(response).to be_successful
    end

    it 'renders the serialized data' do
      allow(UserBlueprint).to receive(:render)
      call_endpoint
      expect(UserBlueprint).to have_received(:render).with(user)
    end
  end
end
