# frozen_string_literal: true

##
# Controller for logging in users.
class SessionsController < ApplicationController
  def destroy
    session.delete(:user_id)
    redirect_to root_path
  end
end
