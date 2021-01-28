class Admin::Auth::ForgotPasswordController < Admin::AuthController
  def index
  end

  def send_otp
    begin
      raise I18n.t('validation.required', param: 'Email address') if params['email'].blank?
      raise I18n.t('validation.invalid', param: 'email address') if params['email'].match(EMAIL_REGEX).nil?

      employee = Employee.find_by_email(params['email'])
      if employee.nil?
        render status: 404, json: { success: false, message: I18n.t('customer.otp_failed'), reason: I18n.t('employee.not_found') }
        return
      end
      raise I18n.t('employee.account_blocked', platform: PlatformConfig['name']) if employee.is_blocked?
    rescue => e
      render status: 400, json: { success: false, message: I18n.t('customer.otp_failed'), reason: { email: [e.message] } }
      return
    end

    render status: 200, json: { success: true, message: I18n.t('customer.otp_success'), 
      data: { auth_token: Employee.send_otp({ param: 'email', value: params['email'] }) } }
    return
  end

  def reset_password
    if params['auth_token'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'Authentication token') }
      return
    end

    begin
      raise I18n.t('validation.required', param: 'OTP') if params['otp'].blank?
      token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] }, { type: Hash }) { nil }
      raise I18n.t('validation.param_expired', param: 'OTP') if token.blank? || params['auth_token'] != token['token'] || token['code'] != params['otp']

      employee = Employee.where(token['param'] => token['value']).first
      if employee.nil?
        render status: 404, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: I18n.t('customer.not_found') }
        return
      end
      raise I18n.t('employee.account_blocked', platform: PlatformConfig['name']) if employee.is_blocked?

      employee.update(password: params['password'], password_confirmation: params['password_confirmation'])
      if employee.errors.any?
        render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: employee.errors.messages }
        return
      end

      Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] })
    rescue => e
      render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: { otp: [e.message] } }
      return
    end

    render status: 200, json: { success: true, message: I18n.t('auth.reset_password.reset_success') }
  end
end
