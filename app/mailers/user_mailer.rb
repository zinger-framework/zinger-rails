class UserMailer < ApplicationMailer
  def send_otp options = {}
    @code = options['code']
    mail(to: options['to'], subject: 'Zinger - OTP Verification')
  end
end
