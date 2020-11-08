class AdminController < ApplicationController
  before_action :authenticate_request, :check_limit

  LIMIT = 20

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
    employee.make_current
  end

  def check_limit
    resp = Core::Ratelimit.reached?(request)
    if resp
      render status: 429, json: { success: false, message: resp }
      return
    end
  end
end
