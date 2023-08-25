# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users, only: %i[new create]

  get 'sign-in', to: 'sessions#new', as: :sign_in
  post 'sign-in', to: 'sessions#create'
  delete 'sign-out', to: 'sessions#destroy', as: :sign_out

  get 'authorize', to: 'oauth#authorize'

  resources :authorization_grants, path: 'authorization-grants', only: %i[new create]

  root 'demo_client#index'
end
