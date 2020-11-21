class AdminController < ApplicationController
  before_action :authenticate_request, :check_limit

  def dashboard
    @title = 'Dashboard'
  end

  private

  def authenticate_request
    employee = !session[:authorization].nil? ? EmployeeSession.fetch_employee(session[:authorization]) : nil
    if employee.nil?
      session.delete(:authorization)
      redirect_to auth_index_path
      return
    end
    payload = EmployeeSession.decode_jwt_token(session[:authorization])
    if payload['two_fa']['verified'] == 1
      return redirect_to otp_auth_index_path
    elsif payload['two_fa']['verified'] != 0 && payload['two_fa']['verified'] != 2
      session.delete(:authorization)
      return redirect_to auth_index_path
    end
    employee.make_current
  end

  def check_limit
    resp = Core::Ratelimit.reached?(request)
    if resp
      render html: resp
      return
    end
  end
end

