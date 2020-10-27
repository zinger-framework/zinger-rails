class V2::CustomerController < ApiController
 
  def profile
    render status: 200, json: { success: true, message: 'success', data: Customer.current.filter_json('profile') }
  end

  def update_profile
    if params['name'].blank?
      render status: 400, json: { success: false, message: I18n.t('profile.update_failed') , reason: I18n.t('validation.required', param: 'Name') }
      return
    end
    Customer.current.update!(name: params['name'])
    render status: 200, json: { success: true, message: 'success', data: Customer.current.filter_json('profile')}
  end

end


