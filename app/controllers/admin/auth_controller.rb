class Admin::AuthController < AdminController
  skip_before_action :authenticate_request
  before_action :verify_auth_token, except: [:index,:login]

  def index
  end

  def login
    if params[:email].present? and params[:password].present?
      employee = Employee.where('email' => params[:email]).first
      if employee.nil? || !employee.authenticate(params[:password])
        flash[:error] = "Email or Password is invalid"
      elsif employee.is_blocked?
        flash[:error] = "User is blocked"
      else
        flash.discard
        employee_session_data = employee.employee_sessions.create!( login_ip: request.ip, user_agent: request.headers['User-Agent'] )
        if employee.two_fa_enabled
          auth_token = Employee.send_otp({ param: 'mobile', value: employee.mobile, action: params['action'] })
          session[:authorization] = employee_session_data.get_jwt_token( { 'verified' => Employee::VERIFIED['2FA_ENABLED_UNVERIFIED'], 'auth_token' => auth_token } )
          redirect_to otp_auth_index_path
        else
          session[:authorization] = employee_session_data.get_jwt_token( { 'verified' => Employee::VERIFIED['2FA_DISABLED_VERIFIED'] } )
          redirect_to dashboard_path
        end
      end
    else
      flash[:error] = "Email and Password must not be empty"
    end
  end

  def otp
    # rate limiting check once
  end

  def otp_login
    if @token['code'] != params['otp']
      flash[:error] = 'Invalid OTP'
      redirect_to otp_auth_index_path
    else
      @payload['two_fa']['verified'] = Employee::VERIFIED['2FA_ENABLED_VERIFIED']
      session[:authorization] = JWT.encode(@payload, AppConfig['api_auth'])
      Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: @payload['two_fa']['auth_token'] })
      redirect_to dashboard_path
    end
  end

  def resend_otp
    employee = Employee.where('id' => @payload['employee_id']).first
    @payload['two_fa']['auth_token'] = Employee.send_otp({ param: 'mobile', value: employee.mobile, action: params['action'] })
    session[:authorization] = JWT.encode(@payload, AppConfig['api_auth'])
  end

  def verify_auth_token
    return redirect_to auth_index_path if session[:authorization].blank?
    @payload = EmployeeSession.decode_jwt_token(session[:authorization])
    return redirect_to auth_index_path if @payload.blank? || @payload['two_fa'].blank?

    if @payload['two_fa']['verified'] == 0 || @payload['two_fa']['verified'] == 2
      redirect_to dashboard_path
    elsif @payload['two_fa']['verified'] == 1
      @token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: @payload['two_fa']['auth_token'] }, { type: Hash }) { nil }
    else
      session.delete(:authorization)
      redirect_to auth_index_path
    end
  end
end

