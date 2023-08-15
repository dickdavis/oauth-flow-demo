# frozen_string_literal: true

##
# Base application controller.
class ApplicationController < ActionController::Base
  helper_method :current_user

  def current_user
    return nil unless (id = session[:user_id])

    @current_user ||= User.find(id)
  end
end
