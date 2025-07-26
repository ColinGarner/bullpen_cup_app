Rails.application.routes.draw do
  devise_for :users

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "home#index"

  # Group creation routes
  get "groups/new", to: "groups#new", as: "new_group"
  post "groups", to: "groups#create", as: "groups"

  # Group join routes (via invite code)
  get "join", to: "group_joins#new", as: "join_group"
  post "join", to: "group_joins#create"

  # Group management routes
  get "select-group", to: "home#select_group", as: "select_group"
  post "groups/:group_slug/switch", to: "home#switch_group", as: "switch_group"

  # Group viewing routes
  get "groups/:group_slug", to: "groups#show", as: "group"
  get "groups/:group_slug/home", to: "groups#dashboard", as: "group_dashboard"

  # Scoring routes for matches (accessible to players)
  resources :matches, only: [] do
    member do
      get :select_tees, to: "scoring#select_tees"
      post :save_tees, to: "scoring#save_tees"
      get :next_hole, to: "scoring#next_hole"
      get "score/hole/:hole", to: "scoring#score_hole", as: :score_hole
      post "score/hole/:hole", to: "scoring#update_score", as: :update_score
      get :leaderboard, to: "scoring#leaderboard"
    end
  end

  # Tournament leaderboard (accessible to all players)
  resources :tournaments, only: [] do
    member do
      get :leaderboard, to: "scoring#tournament_leaderboard"
    end
  end

  # Admin routes scoped to specific groups
  scope path: "/groups/:group_slug" do
    namespace :admin do
      root "dashboard#index", as: "group_admin_root"

      # Group management
      patch "regenerate_invite_code", to: "dashboard#regenerate_invite_code", as: "regenerate_invite_code"
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
              post :create_course
              post :select_course
            end
          end
        end
      end
      resources :teams, only: [ :index ]
              resources :users, only: [ :index, :show ] do
          member do
            patch :promote_to_group_admin
            patch :demote_from_group_admin
          end
        end
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
