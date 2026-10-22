Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "login", to: "auth#login"
      get "me", to: "users#me"
      get "calendar", to: "appointments#calendar"

      resource :dashboard, only: :show

      resources :clients, only: [:index, :show, :create, :update, :destroy]

      resource :account, only: [:show, :update]
      resources :accounts, only: [:index, :show, :create, :update, :destroy]

      resources :resources, only: [:index, :show, :create, :update, :destroy]
      resources :services, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :archived
        end

        member do
          patch :restore
        end
      end
      resources :appointments, only: [:index, :show, :create, :update, :destroy]
      resources :notes, only: [:index, :show, :create, :update, :destroy]

      resources :users, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :update_role
        end

        resources :user_services, only: [:index, :show, :create, :update, :destroy]
      end
      resources :user_invitations, only: [:index, :create] do
        collection do
          post :accept
        end
      end
      resources :password_resets, only: [:create] do
        collection do
          post :confirm
        end
      end
    end
  end
end
