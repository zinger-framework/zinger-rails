class V2::AuthController < ApiController
  AUTH_TYPES = {
    'LOGIN_WITH_PASSWORD' => 'password_auth',
    'LOGIN_WITH_OTP' => 'otp_auth',
    'LOGIN_WITH_GOOGLE' => 'google_auth'
  }

  skip_before_action :authenticate_request, :verify_user
  before_action :verify_auth_type

  def send_otp
    if @auth_type != 'LOGIN_WITH_OTP'
      render status: 400, json: { success: false, message: I18n.t('validation.invalid', param: 'Authentication type') }
      return
    end

    required_keys = %w(email mobile)
    keys_present = required_keys.select { |key| params[key].present? }
    if keys_present.length != 1
      render status: 400, json: { success: false, message: I18n.t('auth.required', param: required_keys.join(', ')) }
      return
    end

    user = User.new(keys_present[0] => params[keys_present[0]])
    user.send("validate_#{keys_present[0]}")
    if user.errors.any?
      render status: 400, json: { success: false, message: I18n.t('user.otp_failed'), reason: user.errors.messages }
      return
    end
    
    render status: 200, json: { success: true, message: I18n.t('user.otp_success'), data: { token: user.send_otp(keys_present[0], params[keys_present[0]]) } }
  end

  private
  def verify_auth_type
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
