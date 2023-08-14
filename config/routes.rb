# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users, only: %i[new create]
  resources :sessions, only: %i[new create]
  root 'home#index'
end
