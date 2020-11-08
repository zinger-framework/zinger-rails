class Employee < ApplicationRecord
  STATUSES = { 'ACTIVE' => 1, 'BLOCKED' => 2 }

  has_secure_password(validations: false)
  default_scope { where(deleted: false) }
  has_many :employee_sessions

  def self.fetch_by_id id
    Core::Redis.fetch(Core::Redis::EMPLOYEE_BY_ID % { id: id }, { type: Employee }) { Employee.find_by_id(id) }
  end

  def is_blocked?
    self.status != STATUSES['ACTIVE']
  end

  def make_current
    Thread.current[:employee] = self
  end

  def self.reset_current
    Thread.current[:employee] = nil
  end

  def self.current
    Thread.current[:employee]
  end
end

