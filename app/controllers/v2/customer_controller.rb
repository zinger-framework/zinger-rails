class V2::CustomerController < ApiController
  def profile
    customer = Customer.current
    render status: 200, json: { 
      success: true, 
      message: I18n.t('profile.found') , 
      data: {
        :name => customer.name.to_s,
        :email => customer.email.to_s,
        :mobile => customer.mobile.to_s,
      }
    }
  end


  def update_profile
    if params['name'].blank?
      render status: 400, json: { success: false, message: I18n.t('validation.required', param: 'name') }
      return
    end
    
    Customer.current.name = params['name']
    if Customer.current.save
      render status: 200, json: { success: true, message: I18n.t('profile.update_success')}
    else 
      render status: 200, json: { success: true, message: I18n.t('profile.update_failed')}
    end
  end
end

