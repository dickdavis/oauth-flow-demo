# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuth::AuthorizationsController do
  describe 'routing' do
    it 'routes to #authorize' do
      expect(get: '/oauth/authorize').to route_to(controller: 'oauth/authorizations', action: 'authorize')
    end
  end
end
