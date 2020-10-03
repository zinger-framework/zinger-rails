class UserMailer < ApplicationMailer
  def email_verification options = {}
    @code = options['code']
    mail(to: options['to'], subject: 'Zinger - Verification')
  end

  def reset_password options = {}
    @link = options['link']
    mail(to: options['to'], subject: 'Zinger - Reset Password')
  end
end
