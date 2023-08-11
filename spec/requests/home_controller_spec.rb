# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomeController do
  describe 'GET /index' do
    subject(:call_endpoint) { get root_path }

    it 'responds with HTTP success' do
      call_endpoint
      expect(response).to have_http_status(:ok)
    end
  end
end
