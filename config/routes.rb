Rails.application.routes.draw do
  root to: 'application#home'

  namespace :v2 do
    namespace :auth, constraints: { subdomain: AppConfig['api_subdomain'], format: :json } do
      resources :signup, only: :none do
        collection do
          post :password
          post :otp
        end
      end

      resources :login, only: :none do
        collection do
          post :password
          post :otp
        end
      end

      delete :logout
      post :reset_password

      resources :otp, only: :none do
        collection do
          post :signup
          post :login
          post :reset_password
        end
      end
    end
  end

  mount Sidekiq::Web => '/sidekiq', subdomain: SidekiqSettings['subdomain']
  
  post '/auth/google_signup/callback' => 'v2/auth/signup#google', :as => :google_signup_callback, constraints: { subdomain: AppConfig['api_subdomain'] }
  post '/auth/google_login/callback' => 'v2/auth/login#google', :as => :google_login_callback, constraints: { subdomain: AppConfig['api_subdomain'] }
  get '/*path', to: 'application#home', constraints: { subdomain: AppConfig['api_subdomain'] }
end
