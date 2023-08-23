# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users, only: %i[new create]

  delete 'sign-out', to: 'sessions#destroy', as: :sign_out

  get 'authorize', to: 'oauth#authorize'
  post 'authenticate', to: 'oauth#authenticate', as: :authenticate

  root 'demo_client#index'
end
