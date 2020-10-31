class V2::Admin::CustomerController < V2::AdminController
  def index
    @title = 'Customers'
    if params['q'].present?
      @customers = if params['q'].match(Customer::EMAIL_REGEX)
        Customer.unscoped.where(email: params['q'])
      elsif params['q'].match(Customer::MOBILE_REGEX)
        Customer.unscoped.where(mobile: params['q'])
      else
        Customer.unscoped.where(id: params['q'])
      end
    end
  end

  def update
    Customer.find_by_id(params['id']).update!(name: params['name'], status: params['status'])
    flash[:success] = 'Update is successful'
    redirect_to v2_admin_customer_index_path(q: params['id'])
  end

  def destroy
    Customer.find_by_id(params['id']).update!(deleted: true)
    flash[:success] = 'Deletion is successful'
    redirect_to v2_admin_customer_index_path(q: params['id'])
  end
end
