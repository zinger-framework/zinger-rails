class AdminController < ApplicationController
  before_action :set_title, :authenticate_request, :check_limit
  AUTHORIZED_2FA_STATUSES = [ Employee::TWO_FA_STATUSES['NOT_APPLICABLE'], Employee::TWO_FA_STATUSES['VERIFIED'] ]

  def dashboard
    @title = 'Dashboard'
  end

  private

  def set_title
    @header = { links: [] }
  end

  def authenticate_request
    employee, payload = session[:authorization].present? ? EmployeeSession.fetch_employee(session[:authorization]) : nil
    if employee.nil?
      session.delete(:authorization)
      flash[:warn] = 'Please login to continue'
      return redirect_to auth_index_path
    end

    return redirect_to otp_auth_index_path if payload['two_fa']['status'] == Employee::TWO_FA_STATUSES['UNVERIFIED']
    
    employee.make_current
  end

  def check_limit
    resp = Core::Ratelimit.reached?(request)
    if resp
      flash[:error] = resp
      return redirect_to request.referrer
    end
  end
end
