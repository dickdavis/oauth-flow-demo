# frozen_string_literal: true

module API
  module V1
    ##
    # API controller for user resources
    class UsersController < API::BaseController
      # GET /api/v1/users/current
      def current
        user = user_from_token
        render json: UserBlueprint.render(user), status: :ok
      end
    end
  end
end
