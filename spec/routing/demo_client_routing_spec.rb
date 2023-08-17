# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DemoClientController do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/').to route_to('demo_client#index')
    end
  end
end
