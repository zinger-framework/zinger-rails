class V2::CustomerController < ApiController
  def profile
    render status: 200, json: { success: true, message: 'success', data: Customer.current.as_json('ui_profile') }
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
    render status: 200, json: { success: true, message: I18n.t('profile.update_success'), data: Customer.current.as_json('ui_profile') }
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
    if token.blank? || params['auth_token'] != token['token'] || token['customer_id'] != Customer.current.id || token['code'] != params['otp']
      render status: 401, json: { success: false, message: I18n.t('profile.reset_failed'),
        reason: { otp: [ I18n.t('customer.param_expired', param: 'OTP') ] } }
      return
    end

    Customer.current.update(token['param'] => token['value'])
    if Customer.current.errors.any?
      render status: 400, json: { success: false, message: I18n.t('profile.reset_failed'), reason: Customer.current.errors.messages }
      return
    end

    Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: params['auth_token'] })
    render status: 200, json: { success: true, message: I18n.t('profile.reset_success'), data: { token: Customer.current.as_json('ui_profile') } }
  end

  def password
    reason_msg = if params['current_password'].blank?
     { current_password: [ I18n.t('validation.required', param: 'Current password') ] }
    elsif params['new_password'].blank?
     { new_password: [ I18n.t('validation.required', param: 'New password') ] }
    elsif params['new_password'].to_s.length < Customer::PASSWORD_MIN_LENGTH
     { new_password: [ I18n.t('customer.password.invalid', length: Customer::PASSWORD_MIN_LENGTH) ] }
    end

    if reason_msg.present?
      render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: reason_msg }
      return
    end

    if Customer.current.authenticate(params['current_password']) == false
      render status: 401, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'),
        reason: { current_password: [ I18n.t('validation.invalid', param: 'Password') ] } }
      return
    end

    Customer.current.update(password: params['new_password'])
    if Customer.current.errors.any?
      render status: 400, json: { success: false, message: I18n.t('auth.reset_password.trigger_failed'), reason: Customer.current.errors.messages }
      return
    end

    render status: 200, json: { success: true, message: I18n.t('auth.reset_password.reset_success') }
  end

  def sessions
    session_data = CustomerSession.where(customer_id: Customer.current.id)
    processed_session_data =[ ]
    session_data.each { |session|  processed_session_data.append(session.as_json('session')) }
    render status: 200, json: { success: true, message: 'success', data: processed_session_data }
  end

  def delete_sessions
    CustomerSession.where(customer_id: Customer.current.id).delete_all
    # Delete all session in redis and check whether delete_all operation is successful
    render status: 200, json: { success: true, message: 'success' }
  end

  def delete_session
    CustomerSession.where(token: params[:id]).delete_all
    # Delete the respective session in redis and check whether delete_all operation is successful
    render status: 200, json: { success: true, message: 'success2' }
  end
end
