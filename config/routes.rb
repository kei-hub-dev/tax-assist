Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  authenticated :user do
    root "home#index", as: :authenticated_root
  end

  unauthenticated :user do
    devise_scope :user do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end

  resource :user_account, only: [ :edit ], controller: :account, path: "account" do
    patch :email
    patch :password
  end
  resource :business, only: [ :edit, :update ], controller: :business
  resources :accounts do
    collection do
      get :sub_categories
      patch :update_sub_categories
    end
  end
  resource :accounting_menu, only: :show, controller: :accounting_menu
  resource :opening_balances, only: [ :show, :update ]
  resources :journal_entries
  namespace :reports do
    resource :general_ledger,   only: :show, controller: :general_ledger
    resource :confirmation,     only: :show, controller: :trial_balance
    resource :income_statement, only: :show, controller: :income_statement
    resource :balance_sheet,    only: :show, controller: :balance_sheet
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker.js", to: "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest.json",     to: "rails/pwa#manifest",       as: :pwa_manifest
  get "books/journal", to: "books#journal", as: :journal_book
  post "select_accounting_period", to: "home#select_accounting_period", as: :select_accounting_period
end
