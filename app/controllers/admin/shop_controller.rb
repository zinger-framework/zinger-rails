class Admin::ShopController < AdminController
  before_action :set_title
  before_action :load_shop, only: [:update, :location, :shop_detail, :destroy]

  def index
    @header[:title] = 'Shops'
    @header[:links].map{ |link| link[:active] = false }

    @shop = Shop.unscoped.find_by_id(params['q']) if params['q'].present?
    @error = nil
  end

  def create
    shop, shop_detail = nil, nil
    ActiveRecord::Base.transaction do
      shop = Shop.new(name: params['name'], lat: params['lat'], lng: params['lng'], tags: params['tags'],
        icon: "shop-icon-#{Time.now.to_i}#{File.extname(params['file'].path)}")
      shop_detail = shop.build_shop_detail(address: { number: params['number'], street: params['street'], area: params['area'],
        city: params['city'], pincode: params['pincode'] }, landline: params['landline'], mobile: params['mobile'],
        opening_time: Time.find_zone(PlatformConfig['time_zone']).strptime(params['opening_time'], '%H:%M').utc, 
        closing_time: Time.find_zone(PlatformConfig['time_zone']).strptime(params['closing_time'], '%H:%M').utc)
      shop_detail.validate
      shop.save unless shop_detail.errors.any?
    end

    if shop_detail.errors.any?
      flash[:error] = shop.errors.messages.values.flatten.first || shop_detail.errors.messages.values.flatten.first
      redirect_to add_shop_shop_index_path
      return
    end

    File.open(params['file'].path, 'rb') { |file| Core::Storage.upload_file(shop.aws_key_path, file) }
    flash[:success] = 'Shop creation is successful'
    redirect_to shop_index_path(q: shop.id)
  end

  def add_shop
    @header[:title] = 'Add New Shop'
    @header[:links].map{ |link| link[:active] = false }
    @header[:links][0][:active] = true
  end

  def update
    @shop.update(name: params['name'], status: params['status'], tags: params['tags'])
    shop_detail = @shop.shop_detail
    shop_detail.update(mobile: params['mobile'], opening_time: Time.find_zone(PlatformConfig['time_zone']).strptime(params['opening_time'], '%H:%M').utc, 
      closing_time: Time.find_zone(PlatformConfig['time_zone']).strptime(params['closing_time'], '%H:%M').utc)
    @shop.update(updated_at: Time.now.utc)

    if @shop.errors.any? || shop_detail.errors.any?
      flash[:error] = @shop.errors.messages.values.flatten.first || shop_detail.errors.messages.values.flatten.first
      redirect_to shop_index_path(q: params['id'])
      return
    end

    flash[:success] = 'Shop update is successful'
    redirect_to shop_index_path(q: params['id'])
  end

  def location
    @shop.update(lat: params['lat'], lng: params['lng'])
    shop_detail = @shop.shop_detail
    shop_detail.update(address: { number: params['number'], street: params['street'], area: params['area'],
      city: params['city'], pincode: params['pincode'] }, landline: params['landline'])
    @shop.update(updated_at: Time.now.utc)

    if @shop.errors.any? || shop_detail.errors.any?
      flash[:error] = @shop.errors.messages.values.flatten.first || shop_detail.errors.messages.values.flatten.first
      redirect_to shop_index_path(q: params['id'])
      return
    end

    flash[:success] = 'Shop location update is successful'
    redirect_to shop_index_path(q: params['id'])
  end

  def shop_detail
    
  end

  def destroy
    @shop.update!(deleted: true)
    flash[:success] = 'Deletion is successful'
    redirect_to shop_index_path(q: params['id'])
  end

  private

  def set_title
    @header = { links: [ { title: 'Add Shop', path: add_shop_shop_index_path } ] }
  end

  def load_shop
    @shop = Shop.fetch_by_id(params['id'])
    if @shop.nil?
      flash[:error] = 'Active shop is not found'
      redirect_to shop_index_path(q: params['id'])
      return
    end
  end
end
