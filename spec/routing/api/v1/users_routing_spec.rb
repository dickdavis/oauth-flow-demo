# frozen_string_literal: true

require 'rails_helper'

RSpec.describe API::V1::UsersController do
  describe 'routing' do
    it 'routes to #current' do
      expect(get: '/api/v1/users/current').to route_to(controller: 'api/v1/users', action: 'current')
    end
  end
end
