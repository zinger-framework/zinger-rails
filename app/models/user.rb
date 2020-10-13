class User < ApplicationRecord
  PASSWORD_MIN_LENGTH = 6
  OTP_LENGTH = 6
  EMAIL_REGEX = /\S+@\S+\.[a-z]+/i
  MOBILE_REGEX = /^[0-9]{10}$/
  STATUSES = { 'ACTIVE' => 1, 'BLOCKED' => 2 }

  has_secure_password(validations: false)
  has_one_time_password length: OTP_LENGTH
  default_scope { where(deleted: false) }
  
  validate :create_validations, on: :create
  after_commit :clear_cache
  after_update :clear_sessions

  has_many :user_sessions

  def self.fetch_by_id id
    Core::Redis.fetch(Core::Redis::USER_BY_ID % { id: id }, { type: User }) { User.find_by_id(id) }
  end

  def validate_email action
    self.email = self.email.to_s.strip.downcase
    errors.add(:email, I18n.t('validation.invalid', param: 'Email address')) unless self.email.match(EMAIL_REGEX)

    if action == 'create'
      return errors.add(:email, I18n.t('validation.already_taken', param: self.email)) if User.exists?(email: self.email)
    elsif action == 'verify'
      user = User.find_by_email(self.email)
      return errors.add(:email, I18n.t('user.not_found')) if user.blank?
      return errors.add(:status, I18n.t('user.account_blocked')) if user.is_blocked?
    end
  end

  def validate_mobile action
    self.mobile = self.mobile.to_s.strip
    errors.add(:mobile, I18n.t('validation.invalid', param: 'Mobile number')) unless self.mobile.match(MOBILE_REGEX)
    
    if action == 'create'
      return errors.add(:mobile, I18n.t('validation.already_taken', param: self.mobile)) if User.exists?(mobile: self.mobile) 
    elsif action == 'verify'
      errors.add(:mobile, I18n.t('user.not_found')) unless User.exists?(mobile: self.mobile) 
      user = User.find_by_mobile(self.mobile)
      return errors.add(:mobile, I18n.t('user.not_found')) if user.blank?
      return errors.add(:status, I18n.t('user.account_blocked')) if user.is_blocked?
    end
  end

  def is_blocked?
    self.status != STATUSES['ACTIVE']
  end

  def make_current
    Thread.current[:user] = self
  end

  def self.reset_current
    Thread.current[:user] = nil
  end

  def self.current
    Thread.current[:user]
  end

  def create_validations
    validate_email('create') if self.email.present?
    validate_mobile('create') if self.mobile.present?
  end

  def send_otp key, value
    self.otp_regenerate_secret
    code = self.otp_code(time: Time.now)
    token = Base64.encode64("#{value}-#{Time.now.to_i}-#{rand(1000..9999)}").strip.gsub('=', '')
    Core::Redis.setex(Core::Redis::OTP_VERIFICATION % { token: token }, { key => value, 'code' => code }, 5.minutes.to_i)
    MailerWorker.perform_async('send_otp', { to: value, code: code, mode: key })
    return token
  end

  def clear_cache
    Core::Redis.delete(Core::Redis::USER_BY_ID % { id: self.id })
  end

  def clear_sessions
    if self.saved_change_to_password_digest?
      UserSession.where(user_id: self.id).delete_all
      Core::Redis.delete(UserSession.cache_key(self.id))
    end
  end
end
