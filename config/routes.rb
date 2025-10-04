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
  resources :accounts

  authenticated :user do
    root "home#index", as: :authenticated_root
  end

  unauthenticated :user do
    devise_scope :user do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end
end
