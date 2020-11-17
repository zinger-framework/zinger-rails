class Admin::AuthController < AdminController
  skip_before_action :authenticate_request

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
          session[:auth_token] = Employee.send_otp({ param: 'mobile', value: employee.mobile, action: 'admin_otp_login' })
          redirect_to otp_auth_index_path
        else
          employee_session_data = employee.employee_sessions.create!( login_ip: request.ip, user_agent: request.headers['User-Agent'] )
          session[:authorization] = employee_session_data.get_jwt_token
          redirect_to customer_index_path
        end
      end
    else
      flash[:error] = "Email and Password must not be empty"
    end
  end

  def otp
    if session[:auth_token].blank?
      redirect_to auth_index_path
      return
    end
  end

  def otp_login
    token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: session[:auth_token] }, { type: Hash }) { nil }
    if token.blank? || session[:auth_token] != token['token'] || token['code'] != params['otp']
      flash[:error] = 'Invalid OTP'
      redirect_to auth_index_path
    else
      employee = Employee.where(token['param'] => token['value']).first
      employee_session_data = employee.employee_sessions.create!( login_ip: request.ip, user_agent: request.headers['User-Agent'] )
      session[:authorization] = employee_session_data.get_jwt_token
      Core::Redis.delete(Core::Redis::OTP_VERIFICATION % { token: session[:auth_token] })
      redirect_to customer_index_path
    end
    session.delete(:auth_token)
  end

  def resend_otp
    token = Core::Redis.fetch(Core::Redis::OTP_VERIFICATION % { token: session[:auth_token] }, { type: Hash }) { nil }
    if token.blank? || session[:auth_token] != token['token']
      flash[:error] = 'Invalid OTP'
      redirect_to auth_index_path
    end
    employee = Employee.where(token['param'] => token['value']).first
    session[:auth_token] = Employee.send_otp({ param: 'mobile', value: employee.mobile, action: 'admin_otp_login' })
  end
end
