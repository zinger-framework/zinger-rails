class User < ApplicationRecord
  attr_accessor :otp

  has_many :user_sessions

  PASSWORD_MIN_LENGTH = 6
  OTP_LENGTH = 6
  EMAIL_REGEX = /\S+@\S+\.[a-z]+/i
  MOBILE_REGEX = /^[0-9]{10}$/
  USER_NAME_REGEX = /^[a-z0-9]{5,}$/i
  OTP_REGEX = /^[0-9]{#{OTP_LENGTH}}$/i

  has_secure_password(validations: false)
  has_one_time_password length: OTP_LENGTH

  def invalid_email is_unique = false
    self.email = email.to_s.strip.downcase
    return I18n.t('validation.required', param: 'Email address') if email.blank?
    return I18n.t('validation.invalid', param: 'Email address') unless email.match(EMAIL_REGEX)
    return I18n.t('validation.already_taken', param: email) if is_unique && User.exists?(email: email)
    return false
  end

  def invalid_mobile is_unique = false
    self.mobile = mobile.to_s.strip
    return I18n.t('validation.required', param: 'Mobile number') if mobile.blank?
    return I18n.t('validation.invalid', param: 'Mobile number') unless mobile.match(MOBILE_REGEX)
    return I18n.t('validation.already_taken', param: mobile) if is_unique && User.exists?(mobile: mobile)
    return false
  end

  def invalid_user_name is_unique = false
    self.user_name = user_name.to_s.strip.downcase
    return I18n.t('validation.required', param: 'User name') if user_name.blank?
    return I18n.t('validation.invalid', param: 'User name') unless user_name.match(USER_NAME_REGEX)
    return I18n.t('validation.already_taken', param: user_name) if is_unique && User.exists?(user_name: user_name)
    return false
  end

  def invalid_password
    return I18n.t('validation.required', param: 'Password') if password.blank?
    return I18n.t('user.password.invalid') if password.length < PASSWORD_MIN_LENGTH
    return false
  end

  def invalid_otp
    self.otp = otp.to_s.strip
    return I18n.t('validation.required', param: 'OTP') if otp.blank?
    return I18n.t('validation.invalid', param: 'OTP') unless otp.match(OTP_REGEX)
    return false
  end

  def send_otp key, value
    self.otp_regenerate_secret
    code = self.otp_code(time: Time.now)
    token = Base64.encode64("#{rand(1000)}-#{value}-#{Time.now.to_i}").strip.gsub('=', '')
    Core::Redis.setex(Core::Redis::OTP_VERIFICATION % { token: token }, { key => value, 'code' => code }, 5.minutes.to_i)
    MailerWorker.perform_async("#{key}_verification", { to: value, code: code })
    return token
  end
end
