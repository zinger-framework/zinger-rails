Rails.application.routes.draw do
  root to: 'application#home'

  namespace :v2 do
    namespace :auth, only: :none, constraints: {subdomain: AppConfig['api_subdomain'], format: :json} do
      post :signup, to: 'signup#create'
      post :login, to: 'login#create'
      delete :logout

      post :forgot_password
      get '/reset_password/:token', action: :verify_reset_link, as: :verify_reset_link
      post :reset_password
      post :send_otp
    end
  end

  mount Sidekiq::Web => '/sidekiq', subdomain: SidekiqSettings['subdomain']
end
