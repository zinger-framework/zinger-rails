class Admin::AuthController < AdminController
  skip_before_action :authenticate_request
  before_action :verify_auth_token, except: [:index,:login]
  AUTHORIZED_2FA_STATUSES = [ Employee::TWO_FA_STATUSES['NOT_APPLICABLE'], Employee::TWO_FA_STATUSES['VERIFIED'] ]

  def index
  end

  def login
    if params[:email].nil? || params[:password].nil?
      return flash[:error] = 'Email and Password must not be empty'
    end

    employee = Employee.where('email' => params[:email]).first
    error_msg = if employee.nil? || !employee.authenticate(params[:password])
      'Email or Password is invalid'
    elsif employee.is_blocked?
      'User is blocked'
    end

    return flash[:error] = error_msg if error_msg.present?
    # todo check if flash.discard is needed here
    employee_session = employee.employee_sessions.create!( login_ip: request.ip, user_agent: request.headers['User-Agent'] )
    if employee.two_fa_enabled
      auth_token = Employee.send_otp( { param: 'mobile', value: employee.mobile, action: params['action'] } )
      session[:authorization] = employee_session.get_jwt_token( { 'status' => Employee::TWO_FA_STATUSES['UNVERIFIED'], 'auth_token' => auth_token } )
      redirect_to otp_auth_index_path
    else
      session[:authorization] = employee_session.get_jwt_token( { 'status' => Employee::TWO_FA_STATUSES['NOT_APPLICABLE'] } )
      redirect_to dashboard_path
    end
  end

  def otp
  end

  def otp_login
    if @token['code'] != params['otp'] || @token['token'] != @payload['two_fa']['auth_token']
      flash[:error] = 'Invalid OTP'
      redirect_to otp_auth_index_path
    else
      @payload['two_fa']['status'] = Employee::TWO_FA_STATUSES['VERIFIED']
      session[:authorization] = Employee.current.employee_sessions.find_by(:token => @payload['token']).get_jwt_token(@payload['two_fa'])
      Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: @payload['two_fa']['auth_token'] })
      redirect_to dashboard_path
    end
  end

  def resend_otp
    @payload['two_fa']['auth_token'] = Employee.send_otp( { param: 'mobile', value: Employee.current.mobile, action: params['action'] } )
    session[:authorization] = Employee.current.employee_sessions.find_by(:token => @payload['token']).get_jwt_token(@payload['two_fa'])
  end

  def verify_auth_token
    employee,@payload = session[:authorization].present? ? EmployeeSession.fetch_employee(session[:authorization]) : nil
    if employee.nil?
      session.delete(:authorization)
      return redirect_to auth_index_path
    end

    if @payload['two_fa']['status'] == Employee::TWO_FA_STATUSES['UNVERIFIED']
      @token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: @payload['two_fa']['auth_token'] }, { type: Hash }) { nil }
    elsif AUTHORIZED_2FA_STATUSES.include? @payload['two_fa']['status']
      return redirect_to dashboard_path
    else
      session.delete(:authorization)
      return redirect_to auth_index_path
    end
    employee.make_current
  end
end

