class AdminController < ApplicationController
  # before_action :authenticate_request, :check_limit
  before_action :authenticate_request

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
      flash[:error] = resp
      render html: 'Welcome to Zinger - Hyperlocal Delivery Framework'
      return
    end
  end
end
