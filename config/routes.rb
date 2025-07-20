Rails.application.routes.draw do
  devise_for :users

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "home#index"

  # Group creation routes
  get "groups/new", to: "groups#new", as: "new_group"
  post "groups", to: "groups#create", as: "groups"

  # Group management routes
  get "select-group", to: "home#select_group", as: "select_group"
  post "groups/:group_slug/switch", to: "home#switch_group", as: "switch_group"

  # Group viewing routes
  get "groups/:group_slug", to: "groups#show", as: "group"
  get "groups/:group_slug/home", to: "groups#dashboard", as: "group_dashboard"

  # Admin routes scoped to specific groups
  scope path: "/groups/:group_slug" do
    namespace :admin do
      root "dashboard#index", as: "group_admin_root"
      resources :tournaments do
        member do
          get :confirm_destroy
        end
        resources :teams, except: [ :index ] do
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
          resources :matches do
            member do
              get :players
              patch :start
              patch :complete
              patch :cancel
              post :add_player
              delete :remove_player
            end
            collection do
              get :search_courses
            end
          end
        end
      end
      resources :teams, only: [ :index ]
      resources :users, only: [ :index, :show ]
    end
  end

  # Legacy admin routes redirect to group selection
  namespace :admin do
    root to: redirect("/select-group")
    get "*path", to: redirect("/select-group")
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
