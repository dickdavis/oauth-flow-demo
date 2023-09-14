# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::SessionsController do
  describe 'routing' do
    it 'routes to #token' do
      expect(post: '/oauth/token').to route_to(controller: 'oauth/sessions', action: 'token')
    end
  end
end
