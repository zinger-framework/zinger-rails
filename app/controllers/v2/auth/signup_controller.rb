class V2::Auth::SignupController < V2::AuthController
  def create
    self.send(@auth_type)
  end

  private
  def password_auth
    required_keys = %w(email mobile user_name)
    keys_present = required_keys.select { |key| params[key].present? }
    if keys_present.length != 1
      render status: 400, json: { success: false, message: I18n.t('auth.required', param: required_keys.join(', ')) }
      return
    end

    user = User.new(keys_present[0] => params[keys_present[0]], password: params['password'], verified: false, \
      two_factor_enabled: false)
    invalid_key = user.send("invalid_#{keys_present[0]}", true) || user.invalid_password

    if invalid_key.class == String
      render status: 400, json: { success: false, message: invalid_key }
    else
      user.save!
      session = user.user_sessions.create!(meta: { type: params['auth_type'] }, login_ip: request.ip, user_agent: params['user_agent'])
      render status: 200, json: { success: true, message: I18n.t('user.login_success'), data: { token: session.get_jwt_token } }
    end
  end

  def otp_auth
    if params['auth_token'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'Authentication token') }
      return
    end

    token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] }, { type: Hash }) { nil }
    if token.blank?
      render status: 400, json: { success: false, message: I18n.t('user.link_expired', param: 'Authentication token') }
      return
    end

    required_keys = %w(email mobile)
    keys_present = required_keys.select { |key| token[key].present? }
    if keys_present.length != 1
      render status: 400, json: { success: false, message: I18n.t('auth.required', param: required_keys.join(', ')) }
      return
    end

    user = User.new(keys_present[0] => token[keys_present[0]], otp: params['otp'], verified: true, two_factor_enabled: false)
    invalid_key = user.send("invalid_#{keys_present[0]}", true) || user.invalid_otp

    if invalid_key.class == String
      render status: 400, json: { success: false, message: invalid_key }
    elsif token['code'] != params['otp']
      render status: 400, json: { success: false, message: I18n.t('user.link_expired', param: 'OTP') }
    else
      user.save!
      session = user.user_sessions.create!(meta: { type: params['auth_type'] }, login_ip: request.ip, user_agent: params['user_agent'])
      Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] })
      render status: 200, json: { success: true, message: I18n.t('user.login_success'), data: { token: session.get_jwt_token } }
    end
  end

  def google_auth
    user = User.new('email' => params['email'], verified: true, two_factor_enabled: false)
    invalid_key = user.invalid_email(true)
    if invalid_key.class == String
      render status: 400, json: { success: false, message: invalid_key }
    else
      user.save!
      session = user.user_sessions.create!(meta: { type: params['auth_type'] }, login_ip: request.ip)
      render status: 200, json: { success: true, message: I18n.t('user.login_success'), data: { token: session.get_jwt_token } }
    end
  end
end
