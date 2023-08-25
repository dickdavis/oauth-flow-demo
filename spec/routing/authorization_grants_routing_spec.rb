# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthorizationGrantsController do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/authorization-grants/new').to route_to('authorization_grants#new')
    end

    it 'routes to #create' do
      expect(post: '/authorization-grants').to route_to('authorization_grants#create')
    end
  end
end
