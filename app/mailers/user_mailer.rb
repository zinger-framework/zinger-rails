class UserMailer < ApplicationMailer
  def self.send_otp options = {}
    @code = options['code']
    mail(to: options['to'], subject: 'Zinger - OTP Verification')
  end
end
