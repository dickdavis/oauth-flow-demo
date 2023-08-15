# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users, only: %i[new create]
  resources :sessions, only: %i[new create]
  delete 'sign-out', to: 'sessions#destroy', as: :sign_out
  root 'home#index'
end
