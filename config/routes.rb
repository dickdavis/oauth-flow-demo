# frozen_string_literal: true

##
# Provides a route constraint for matching `grant_type`
GrantTypeConstraint = Struct.new(:grant_type) do
  def matches?(request)
    request.request_parameters['grant_type'] == grant_type
  end
end

Rails.application.routes.draw do
  resources :users, only: %i[new create]

  get 'sign-in', to: 'sessions#new', as: :sign_in
  post 'sign-in', to: 'sessions#create'
  delete 'sign-out', to: 'sessions#destroy', as: :sign_out

  namespace :oauth do
    get 'authorize', to: 'authorizations#authorize'

    resources :authorization_grants, path: 'authorization-grants', only: %i[new create]

    constraints(GrantTypeConstraint.new('refresh_token')) do
      post 'token', to: 'sessions#refresh', as: :refresh_session
    end

    constraints(GrantTypeConstraint.new('authorization_code')) do
      post 'token', to: 'sessions#token', as: :create_session
    end

    post 'token', to: 'sessions#unsupported_grant_type', as: :unsupported_grant_type
  end

  namespace :api, format: :json do
    namespace :v1 do
      scope :users do
        get 'current', to: 'users#current', as: :current_user
      end
    end
  end

  root 'demo_client#index'
end
