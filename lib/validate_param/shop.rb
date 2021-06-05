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

    if params['deleted'].present?
      return 'Invalid param - deleted' unless %w(true false).include? params['deleted'].to_s
      conditions['deleted'] = params['deleted'].to_s == 'true'
    end

    return conditions
  end
end
