class ValidateParam::Shop
  def self.load_conditions params
    conditions = {}

    if params['statuses'].class == String
      status = ::Shop::STATUSES[params['statuses']]
      conditions['status'] = status if status.present?
    elsif params['statuses'].class == Array
      statuses = params['statuses'].to_a.map { |status| ::Shop::STATUSES[status] }.compact
      conditions['status'] = statuses if statuses.present?
    end

    return conditions
  end
end
