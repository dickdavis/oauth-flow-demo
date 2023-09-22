# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::SessionsController do
  describe 'routing' do
    it 'routes to #refresh' do
      skip 'This route cannot be tested here due to an limitation of routings specs with respect to constraints'
      expect(
        post: '/oauth/token', grant_type: 'refresh_token'
      ).to route_to(controller: 'oauth/sessions', action: 'refresh')
    end

    it 'routes to #token' do
      expect(post: '/oauth/token').to route_to(controller: 'oauth/sessions', action: 'token')
    end
  end
end
