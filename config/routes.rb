Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  get "home/index"
  
  # Admin routes - protected by authentication in controller
  namespace :admin do
    root "dashboard#index"
    resources :tournaments do
      member do
        patch :start
        patch :complete
        patch :cancel
        get :confirm_destroy
      end
      
      # Nested resources for teams and rounds
      resources :teams do
        member do
          post :add_player
          delete :remove_player
        end
      end
      
      resources :rounds do
        member do
          patch :start
          patch :complete
          patch :cancel
        end
      end
    end
    
    # Standalone teams resource for cross-tournament management if needed
    resources :teams, only: [:index]
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
