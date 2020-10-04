Rails.application.routes.draw do
  root to: 'application#home'

  get 'admin/index'
  
  namespace :v2 do
    namespace :auth, constraints: {subdomain: AppConfig['api_subdomain'], format: :json} do
      post :signup, to: 'signup#create'
      post :login, to: 'login#create'
      post :send_otp
    end

    namespace :admin, constraints: {subdomain: AppConfig['admin_subdomain']} do 
      resources :configuration, only: [:index,:create,:update,:destroy] 
    end
    
  end

  mount Sidekiq::Web => '/sidekiq', subdomain: SidekiqSettings['subdomain']
end
