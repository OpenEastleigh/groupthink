# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users

  # Login
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    get "sign_in", to: "devise/sessions#new", as: :new_user_session
    delete "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end

  resources :proposals do
    member do
      post :comment
    end
  end

  resources :ideas do
  end

  post "webhook", to: "proposals#webhook", as: :webhook

  constraints(path: /[^\?]+/) do
    get "/edit/:branch/*path": "edit#edit", format: false
    get "/new/:branch": "edit#new", format: false
  end
  post "/edit/message": "edit#message"
  post "/edit/commit": "edit#commit"
  get "/edit": "edit#index"


  root "proposals#index"
end
