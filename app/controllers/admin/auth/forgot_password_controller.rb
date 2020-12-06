class Admin::Auth::ForgotPasswordController < Admin::AuthController
  before_action :go_to_dashboard, except: [:resend_otp, :reset_password]
  before_action :verify_jwt_token, only: [:resend_otp, :reset_password]

  def index
  end

  def send_otp
  end

  def resend_otp
  end

  def reset_password
  end
end
