Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  mount MissionControl::Jobs::Engine, at: "/admin/jobs"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]
  resource :password_reset, only: %i[new create], path: "password-reset"
  get "password-reset/:token" => "password_resets#edit", as: :edit_password_reset_token
  patch "password-reset/:token" => "password_resets#update", as: :password_reset_token

  namespace :admin do
    root "dashboard#index"
    get "service-actions" => "service_actions#index", as: :service_actions
    resources :users, only: %i[index edit update] do
      patch :status, on: :member
    end
  end

  get "dashboard" => "dashboard#show", as: :dashboard
  resources :waterfalls, only: %i[index show], param: :slugged_public_id do
    collection do
      get :map_data
    end
  end

  root "waterfalls#index"
end
