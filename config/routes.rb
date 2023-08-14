# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users, only: %i[new create]

  post 'sign-in', to: 'sessions#create', as: :sign_in
  delete 'sign-out', to: 'sessions#destroy', as: :sign_out

  get 'authorize', to: 'oauth#authorize'

  root 'demo_client#index'
end
