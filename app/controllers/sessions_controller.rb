# frozen_string_literal: true

##
# Controller for logging in users.
class SessionsController < ApplicationController
  # rubocop:disable Metrics/AbcSize
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id.to_s
      redirect_to root_path
    else
      flash.now.alert = t('.login_failure')
      render 'oauth/authorize', locals: { state: params[:state] }
    end
  end
  # rubocop:enable Metrics/AbcSize

  def destroy
    session.delete(:user_id)
    redirect_to root_path
  end
end
