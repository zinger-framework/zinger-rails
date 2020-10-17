Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, AppConfig['google_client_id'], AppConfig['google_client_secret'],
    name: 'google_signup', prompt: 'none', scope: 'email', provider_ignores_state: true, skip_jwt: true

  provider :google_oauth2, AppConfig['google_client_id'], AppConfig['google_client_secret'],
    name: 'google_login', prompt: 'none', scope: 'email', provider_ignores_state: true, skip_jwt: true
end
