class Admin::AuthController < AdminController
  skip_before_action :authenticate_request, only: :index

  def index
    if params[:email].present? and params[:password].present?
      employee = Employee.where('email' => params[:email]).first
      if employee.nil? || !employee.authenticate(params[:password])
        flash[:error] = "Email or Password is invalid"
      elsif employee.is_blocked?
        flash[:error] = "User is blocked"
      else
        if employee.otp_secret_key.present?
          render html: 'Please verify OTP Authentication'
        else
          employee_session_data = employee.employee_sessions.create!( login_ip: request.ip, user_agent: request.headers['User-Agent'] )
          session[:authorization] = employee_session_data.get_jwt_token
          redirect_to customer_index_path
        end
      end
    end
  end
end


