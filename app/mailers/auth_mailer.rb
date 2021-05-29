class AuthMailer < ApplicationMailer
  def sms_otp options = {}
    @code = options['code']
    mail(to: options['value'], subject: 'Zinger - OTP Verification')
  end
end
