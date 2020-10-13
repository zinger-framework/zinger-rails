class V2::AuthController < ApiController
  AUTH_TYPES = {
    'LOGIN_WITH_PASSWORD' => 'password_auth',
    'LOGIN_WITH_OTP' => 'otp_auth',
    'LOGIN_WITH_GOOGLE' => 'google_auth'
  }
  OTP_ACTION_TYPES = %w(create verify)
  AUTH_PARAMS = %w(email mobile)

  skip_before_action :authenticate_request, except: :logout
  before_action :verify_auth_type, except: :logout

  def send_otp
    if @auth_type == 'LOGIN_WITH_GOOGLE'
      render status: 400, json: { success: false, message: I18n.t('validation.invalid', param: 'Authentication type') }
      return 
    end

    if params['action_type'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'Action type') }
      return
    elsif !OTP_ACTION_TYPES.include?(params['action_type'])
      render status: 400, json: { success: false, message: I18n.t('validation.invalid', param: 'Action type') }
      return
    end

    params_present = AUTH_PARAMS.select { |key| params[key].present? }
    if params_present.length != 1
      render status: 400, json: { success: false, message: I18n.t('auth.required', param: AUTH_PARAMS.join(', ')) }
      return
    end

    params_present = params_present.first
    user = User.new(params_present => params[params_present])
    user.send("validate_#{params_present}", params['action_type'])
    if user.errors.any?
      render status: 400, json: { success: false, message: I18n.t('user.otp_failed'), reason: user.errors.messages }
      return
    end
    
    render status: 200, json: { success: true, message: I18n.t('user.otp_success'), data: { token: user.send_otp(params_present, params[params_present]) } }
  end

  def logout
    session = User.current.user_sessions.find_by_token(UserSession.extract_token(request.headers['Authorization']))
    if session.present? && session.destroy
      render status: 200, json: { success: true, message: I18n.t('auth.logout_success') }
      return
    end

    render status: 200, json: { success: false, message: I18n.t('auth.logout_failed') }
  end
  
  def reset_password
    if @auth_type != 'LOGIN_WITH_PASSWORD'
      render status: 400, json: { success: false, message: I18n.t('validation.invalid', param: 'Authentication type') }
      return
    end

    if params['auth_token'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'Authentication token') }
      return
    end

    if params['otp'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'OTP') }
      return
    end

    if params['password'].blank?
      render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: { password: [ I18n.t('validation.required', param: 'Password') ] } }
      return
    elsif params['password'].to_s.length < User::PASSWORD_MIN_LENGTH
      render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: { password: [ I18n.t('user.password.invalid', length: User::PASSWORD_MIN_LENGTH) ] } }
      return
    end

    token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] }, { type: Hash }) { nil }
    if token.blank? || token['code'] != params['otp']
      render status: 401, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: { otp: [ I18n.t('user.param_expired', param: 'OTP') ] } }
      return
    end
    
    params_present = AUTH_PARAMS.select { |key| token[key].present? }.first
    @user = User.where(params_present => token[params_present]).first
    if @user.nil?
      render status: 404, json: { success: false, message: I18n.t('user.not_found') }
      return
    elsif @user.is_blocked?
      render status: 400, json: { success: false, message: I18n.t('user.account_blocked') }
      return
    end

    @user.update!(password: params['password'])
    Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] })
    render status: 200, json: { success: true, message: I18n.t('auth.reset_password.reset_success') }
  end

  private
  def verify_auth_type
    # TODO: Replace the CoreConfig.yml
    auth_types = Core::Configuration.get(CoreConfig['auth']['methods'])
    if auth_types.class == String
      @auth_type = auth_types
    elsif params['auth_type'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'Authentication type') }
      return
    elsif !AUTH_TYPES.key?(params['auth_type'])
      render status: 400, json: { success: false, message: I18n.t('validation.invalid', param: 'Authentication type') }
      return
    elsif !auth_types.include? params['auth_type']
      render status: 400, json: { success: false, message: I18n.t('validation.unconfigured', param: 'Authentication type') }
      return
    else
      @auth_type = params['auth_type']
    end
  end

end
