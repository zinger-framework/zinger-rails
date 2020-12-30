class Admin::AuthController < AdminController
  skip_before_action :authenticate_request, except: :logout

  def logout
    Employee.current.employee_sessions.find_by_token(EmployeeSession.extract_token(session[:authorization])).destroy!
    session.delete(:authorization)
    flash[:success] = I18n.t('auth.logout_success')
    redirect_to auth_login_index_path
  end

  private

  def verify_jwt_token
    @employee, @payload = session[:authorization].present? ? EmployeeSession.fetch_employee(session[:authorization]) : nil
    if @employee.nil?
      session.delete(:authorization)
    elsif @payload['two_fa']['status'] == Employee::TWO_FA_STATUSES['UNVERIFIED']
      @employee.make_current
    else
      return redirect_to dashboard_path
    end
  end
end
