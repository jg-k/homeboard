Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  root "home#index"
  get "getting-started", to: "pages#getting_started", as: :getting_started

  # Activity log
  get "activity", to: "activity#index", as: :activity
  get "activity/history", to: "activity#history", as: :activity_history
  get "activity/day/:date", to: "activity#day", as: :activity_day

  # Settings
  get "settings", to: "settings#index", as: :settings
  patch "settings/toggle_allow_follows", to: "settings#toggle_allow_follows", as: :toggle_allow_follows_settings
  delete "settings/clear_imported_ascents", to: "settings#clear_imported_ascents", as: :clear_imported_ascents_settings
  get "settings/export_json", to: "settings#export_json", as: :export_json_settings
  get "settings/export_csv", to: "settings#export_csv", as: :export_csv_settings

  # Buddies (follows)
  resources :buddies, only: [ :index, :create, :destroy ] do
    member do
      get :activity
      get "day/:date", action: :day, as: :day
      get "exercise_chart/:exercise_type_id", action: :exercise_chart, as: :exercise_chart
    end
  end

  # Grading systems
  resources :grading_systems, except: [ :index ] do
    member do
      post :set_as_default
    end
  end

  # Exercise types and logging
  resources :exercise_types do
    resources :targets, only: [ :create, :destroy ]
  end
  resources :exercises, only: [ :new, :create, :edit, :update, :destroy ]

  # Metrics and measurements (separate from activity log)
  resources :metrics do
    resources :measurements, only: [ :create, :edit, :update, :destroy ]
    resources :targets, only: [ :create, :destroy ], controller: "metric_targets"
  end
  resources :gym_sessions, only: [ :new, :create, :edit, :update, :destroy ]
  resources :hikes, only: [ :new, :create, :edit, :update, :destroy ]
  resources :crag_ascent_imports, only: [ :new, :create ] do
    collection do
      post :sync_thecrag
    end
  end
  resources :crag_ascents, only: [ :destroy ]

  # Boardsesh integration
  resource :boardsesh_connection, only: [ :new, :create, :destroy ]
  resource :boardsesh_sync, only: [ :create ]
  resource :boardsesh_data, only: [ :destroy ]

  # Stats
  get "stats", to: "stats#index", as: :stats

  # Tracking (exercises & metrics combined)
  get "tracking", to: "tracking#index", as: :tracking

  # Admin
  namespace :admin do
    resources :users, only: [ :index, :update, :destroy ]
  end

  # Problems landing redirect
  get "problems", to: "problems#landing", as: :problems_landing

  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  resources :boards do
    member do
      patch :soft_delete
      get :export
    end
    resources :board_layouts, only: [ :create, :update ] do
      member do
        patch :soft_delete
        patch :archive
      end
    end
    resources :problems, except: [ :destroy ] do
      member do
        patch :soft_delete
      end
      collection do
        get :filter
      end
      resources :board_climbs, only: [ :create, :edit, :update, :destroy ]
      resource :circuit_chart, only: [ :show ]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
