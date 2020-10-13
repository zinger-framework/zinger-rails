class SmsMailer
  def self.send_otp options = {}
    mobile = options['to']
    otp_code = options['code']
    # TODO: Integrate with any SMS gateways
  end
end
