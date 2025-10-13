Rails.application.routes.draw do
  devise_for :users

  resource :user_account, only: [ :edit ], controller: :account, path: "account" do
    patch :email
    patch :password
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  post "select_accounting_period", to: "home#select_accounting_period", as: :select_accounting_period
  resource :accounting_menu, only: :show, controller: :accounting_menu
  resource :business, only: [ :edit, :update ], controller: :business
  resource :opening_balances, only: [ :show, :update ], controller: :opening_balances

  resources :accounts do
    collection do
      get :sub_categories
      patch :update_sub_categories
    end
  end
  resources :journal_entries

  get "books/journal", to: "books#journal", as: :journal_book
  get "reports/general_ledger", to: "reports/general_ledger#show", as: :reports_general_ledger
  get "reports/confirmation", to: "reports/trial_balance#show", as: :reports_confirmation
  get "reports/income_statement", to: "reports/income_statement#show", as: :reports_income_statement
  get "reports/balance_sheet",   to: "reports/balance_sheet#show",   as: :reports_balance_sheet

  authenticated :user do
    root "home#index", as: :authenticated_root
  end

  unauthenticated :user do
    devise_scope :user do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end
end
