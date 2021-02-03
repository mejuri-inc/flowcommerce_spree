# frozen_string_literal: true

Rails.application.routes.draw do
  ### Devise routes
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    registrations: 'users/registrations'
  }

  devise_scope :user do
    get 'api/checkout_url' => 'users/sessions#checkout_url'
    get 'session_current' => 'users/sessions#get_session_current', as: :get_session_current
  end

  # Root Path
  root to: 'home#index'
end
