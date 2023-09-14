# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users, only: %i[new create]

  get 'sign-in', to: 'sessions#new', as: :sign_in
  post 'sign-in', to: 'sessions#create'
  delete 'sign-out', to: 'sessions#destroy', as: :sign_out

  namespace :oauth do
    get 'authorize', to: 'authorizations#authorize'
    post 'token', to: 'sessions#token'
  end

  resources :authorization_grants, path: 'authorization-grants', only: %i[new create]

  namespace :api, format: :json do
    namespace :v1 do
      scope :users do
        get 'current', to: 'users#current', as: :current_user
      end
    end
  end

  root 'demo_client#index'
end
