class AdminController < ApplicationController
  before_action :set_title, :authenticate_request, :check_limit

  def dashboard
    @title = 'Dashboard'
  end

  private
  AUTHORIZED_2FA_STATUSES = [ Employee::TWO_FA_STATUSES['NOT_APPLICABLE'], Employee::TWO_FA_STATUSES['VERIFIED'] ]

  def authenticate_request
    employee,payload = session[:authorization].present? ? EmployeeSession.fetch_employee(session[:authorization]) : nil
    if employee.nil?
      session.delete(:authorization)
      return redirect_to auth_index_path
    end

    if payload['two_fa']['status'] == Employee::TWO_FA_STATUSES['UNVERIFIED'] && payload['two_fa']['auth_token'].present?
      return redirect_to otp_auth_index_path
    elsif !AUTHORIZED_2FA_STATUSES.include? payload['two_fa']['status']
      session.delete(:authorization)
      return redirect_to auth_index_path
    end
    employee.make_current
  end

  def check_limit
    resp = Core::Ratelimit.reached?(request)
    if resp
      flash[:error] = resp
      return redirect_to request.referrer
    end
  end

  def set_title
    @header = { links: [] }
  end
end

