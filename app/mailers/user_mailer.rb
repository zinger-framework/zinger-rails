class UserMailer < ApplicationMailer
  def send_otp options = {}
    @code = options['code']
    mail(to: options['to'], subject: 'Zinger - OTP Verification')
  end

  def reset_password options = {}
    @link = options['link']
    mail(to: options['to'], subject: 'Zinger - Reset Password')
  end
end
