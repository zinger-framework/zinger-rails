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
        if employee.two_fa_enabled
          session[:auth_token] = Employee.send_otp({ param: 'mobile', value: employee.mobile, action: params['action'] })
          redirect_to otp_auth_index_path
        else
          employee_session_data = employee.employee_sessions.create!( login_ip: request.ip, user_agent: request.headers['User-Agent'] )
          session[:authorization] = employee_session_data.get_jwt_token
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
      employee = Employee.where(@token['param'] => @token['value']).first
      employee_session_data = employee.employee_sessions.create!( login_ip: request.ip, user_agent: request.headers['User-Agent'] )
      session[:authorization] = employee_session_data.get_jwt_token
      Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: session[:auth_token] })
      session.delete(:auth_token)
      redirect_to dashboard_path
    end
  end

  def resend_otp
    employee = Employee.where(@token['param'] => @token['value']).first
    session[:auth_token] = Employee.send_otp({ param: 'mobile', value: employee.mobile, action: 'admin_otp_login' })
  end

  def verify_auth_token
    return redirect_to dashboard_path if !session[:authorization].blank?
    return redirect_to auth_index_path if session[:auth_token].blank?
    @token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: session[:auth_token] }, { type: Hash }) { nil }

    if @token.blank? || session[:auth_token] != @token['token']
      flash[:error] = 'Invalid OTP'
      session.delete(:auth_token)
      redirect_to auth_index_path
    end
  end
end

