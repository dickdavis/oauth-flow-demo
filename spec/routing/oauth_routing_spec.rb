# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OAuthController do
  describe 'routing' do
    it 'routes to #authorize' do
      expect(get: '/authorize').to route_to('oauth#authorize')
    end
  end
end
