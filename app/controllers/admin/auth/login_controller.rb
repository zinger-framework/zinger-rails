class Admin::Auth::LoginController < Admin::AuthController
  before_action :verify_jwt_token

  def index
  end

  def create
    error_msg = if params['user_type'].blank?
      I18n.t('validation.required', param: 'User type')
    elsif !%w(Admin Employee).include? params['user_type']
      I18n.t('validation.invalid', param: 'user type')
    elsif params['email'].blank?
      I18n.t('validation.required', param: 'Email')
    elsif params['password'].to_s.length < PASSWORD_MIN_LENGTH
      I18n.t('validation.password.invalid', length: PASSWORD_MIN_LENGTH)
    end

    if error_msg.present?
      flash[:danger] = error_msg
      return redirect_to auth_login_index_path
    end

    employee = case params['user_type']
    when 'Employee'
      Employee.find_by_email(params['email'])
    end

    error_msg = if employee.nil?
      I18n.t('employee.not_found')
    elsif employee.is_blocked?
      I18n.t('employee.account_blocked', platform: PlatformConfig['name'])
    elsif employee.authenticate(params['password']) == false
      I18n.t('validation.invalid', param: 'password')
    end
    
    if error_msg.present?
      flash[:danger] = error_msg
      return redirect_to auth_login_index_path
    end

    emp_session = employee.employee_sessions.create!(login_ip: request.ip, user_agent: request.headers['User-Agent'])
    if employee.two_fa_enabled
      session[:authorization] = emp_session.get_jwt_token({ 'status' => Employee::TWO_FA_STATUSES['UNVERIFIED'],
        'auth_token' => Employee.send_otp({ param: 'mobile', value: employee.mobile }) })
      flash[:success] = I18n.t('employee.otp_success')
      redirect_to auth_login_index_path
    else
      session[:authorization] = emp_session.get_jwt_token({ 'status' => Employee::TWO_FA_STATUSES['NOT_APPLICABLE'] })
      redirect_to dashboard_path
    end
  end

  def resend_otp
    @payload['two_fa']['auth_token'] = Employee.send_otp({ param: 'mobile', value: @employee.mobile })
    session[:authorization] = @employee.employee_sessions.find_by_token(@payload['token']).get_jwt_token(@payload['two_fa'])
    flash[:success] = I18n.t('employee.otp_success')
    redirect_to auth_login_index_path
  end

  def verify_otp
    @token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: @payload['two_fa']['auth_token'] }, { type: Hash }) { nil }
    if @token.blank? || @token['token'] != @payload['two_fa']['auth_token'] || @token['code'] != params['otp']
      flash[:danger] = I18n.t('validation.param_expired', param: 'OTP')
      return redirect_to auth_login_index_path
    end

    @payload['two_fa']['status'] = Employee::TWO_FA_STATUSES['VERIFIED']
    session[:authorization] = @employee.employee_sessions.find_by_token(@payload['token']).get_jwt_token(@payload['two_fa'])
    Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: @payload['two_fa']['auth_token'] })
    redirect_to dashboard_path
  end
end
