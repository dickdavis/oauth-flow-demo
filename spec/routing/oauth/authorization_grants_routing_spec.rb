# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AuthorizationGrantsController do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/oauth/authorization-grants/new')
        .to route_to(controller: 'oauth/authorization_grants', action: 'new')
    end

    it 'routes to #create' do
      expect(post: '/oauth/authorization-grants')
        .to route_to(controller: 'oauth/authorization_grants', action: 'create')
    end
  end
end
