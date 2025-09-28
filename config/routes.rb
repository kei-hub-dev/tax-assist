Rails.application.routes.draw do
  devise_for :users

  resource :account, only: [:edit], controller: :account do
    patch :email
    patch :password
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  authenticated :user do
    root "home#index", as: :authenticated_root
  end

  unauthenticated :user do
    devise_scope :user do
      root "devise/sessions#new", as: :unauthenticated_root
    end
  end
end
