class V2::CustomerController < ApiController
  def profile
    render status: 200, json: { success: true, message: 'success', data: Customer.current.as_json('profile') }
  end

  def update_profile
    if params['name'].blank?
      render status: 400, json: { success: false, message: I18n.t('profile.update_failed'),
        reason: { name: [ I18n.t('validation.required', param: 'Name') ] } }
      return
    end

    Customer.current.update(name: params['name'])
    if Customer.current.errors.any?
      render status: 400, json: { success: false, message: I18n.t('profile.update_failed'), reason: Customer.current.errors.messages }
      return
    end
    render status: 200, json: { success: true, message: I18n.t('profile.update_success'), data: Customer.current.as_json('profile') }
  end

  def reset_profile
    if params['auth_token'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'Authentication token') }
      return
    elsif params['otp'].blank?
      render status: 400, json: { success: false, message: I18n.t('profile.reset_failed'),
        reason: { otp: [ I18n.t('validation.required', param: 'OTP') ] } }
      return
    end

    token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] }, { type: Hash }) { nil }
    if token.blank? || params['auth_token'] != token['token'] || token['code'] != params['otp']
      render status: 401, json: { success: false, message: I18n.t('profile.reset_failed'),
        reason: { otp: [ I18n.t('customer.param_expired', param: 'OTP') ] } }
      return
    end

    Customer.current.update_attributes(token['param'] => token['value'])
    if Customer.current.errors.any?
      render status: 400, json: { success: false, message: I18n.t('profile.reset_failed'), reason: Customer.current.errors.messages }
      return
    end

    Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] })
    render status: 200, json: { success: true, message: I18n.t('profile.reset_success'), data: { token: Customer.current.as_json('profile') } }
  end

  def password
    reason_msg = if params['current_password'].blank?
     { 'Current Password': I18n.t('validation.required', param: 'Current password') }
    elsif params['new_password'].blank?
     { 'New Password': I18n.t('validation.required', param: 'New password') }
    elsif params['current_password'].to_s.length < Customer::PASSWORD_MIN_LENGTH
     { 'Current Password': I18n.t('customer.password.invalid', length: Customer::PASSWORD_MIN_LENGTH) }
    elsif params['new_password'].to_s.length < Customer::PASSWORD_MIN_LENGTH
     { 'New Password': I18n.t('customer.password.invalid', length: Customer::PASSWORD_MIN_LENGTH) }
    end

    if reason_msg.present?
      render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: reason_msg  }
      return
    end

    if Customer.current.authenticate(params['current_password']) == false
      render status: 401, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'),
        reason: { password: [ I18n.t('validation.invalid', param: 'Password') ] } }
      return
    end

    Customer.current.update_attributes(password: params['new_password'])
    if Customer.current.errors.any?
      render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: Customer.current.errors.messages }
      return
    end
    render status: 200, json: { success: true, message: I18n.t('auth.reset_password.reset_success') }
  end
end

