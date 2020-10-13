class MailerWorker
  include Sidekiq::Worker

  def perform(mail, options = {})
    send(mail, options)
  end

  def send_otp options
    case options['mode']
    when 'mobile'
      SmsMailer.send_otp(options)
    when 'email'
      UserMailer.send_otp(options).deliver!
    end
    Rails.logger.debug "==== OTP:#{options['code']} sent to #{options['to']} ===="
  end

end
