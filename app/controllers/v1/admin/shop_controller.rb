class V1::Admin::ShopController < AdminController
  before_action :load_shop, except: :new

  def new
    shop = Employee.current.shops.where(status: Shop::STATUSES['PENDING']).first
    shop = Employee.current.shops.create if shop.nil?
    render status: 200, json: { success: true, message: 'success', data: { shop: shop.as_json('admin_shop') } }
  end

  def show
    render status: 200, json: { success: true, message: 'success', data: { shop: @shop.as_json('admin_shop') } }
  end

  def update
    %w(name email).each { |key| @shop.send("#{key}=", params[key].to_s.strip) if params[key].present? }
    @shop.tags = params['tags'].join(' ') if params['tags'].present?
    @shop.category = Shop::CATEGORIES[params['category'].to_s.strip.upcase]
    @shop.lat, @shop.lng = params['lat'].to_f, params['lng'].to_f if params['lat'].present? && params['lng'].present?

    @shop.validate
    if @shop.errors.any?
      render status: 400, json: { success: false, message: I18n.t('shop.update_failed'), reason: @shop.errors }
      return
    end

    shop_detail = @shop.shop_detail
    shop_detail.payment = shop_detail.payment.merge(params.as_json.slice(*%w(account_number account_ifsc account_holder pan gst))
      .transform_values { |v| v.to_s.strip }.select { |key| params[key].present? })
    shop_detail.address = shop_detail.address.merge(params.as_json.slice(*%w(street area city state pincode))
      .transform_values { |v| v.to_s.strip }.select { |key| params[key].present? })
    %w(telephone mobile description).each { |key| shop_detail.send("#{key}=", params[key].to_s.strip) if params[key].present? }
    %w(opening_time closing_time).each { |key| shop_detail.send("#{key}=", 
      Time.find_zone(PlatformConfig['time_zone']).strptime(params[key], '%H:%M').utc) if params[key].present? }

    shop_detail.validate
    if shop_detail.errors.any?
      render status: 400, json: { success: false, message: I18n.t('shop.update_failed'), reason: shop_detail.errors }
      return
    end

    shop_detail.save!(validate: false)
    @shop.save!(validate: false)
    render status: 200, json: { success: true, message: I18n.t('shop.update_success'), data: { shop: @shop.as_json('admin_shop') } }
  end

  def destroy
    @shop.update!(deleted: true)
    render status: 200, json: { success: true, message: I18n.t('shop.delete_success') }
  end

  def icon
    @shop.update!(icon: "shop-icon-#{Time.now.to_i}#{File.extname(params['file'].path)}")
    File.open(params['file'].path, 'rb') { |file| Core::Storage.upload_file(@shop.aws_key_path, file) }
    flash[:success] = 'Icon upload is successful'
    redirect_to shop_index_path(q: params['id'])
  end

  def cover_photo
    @shop.shop_detail.update!(cover_photos: @shop.shop_detail.cover_photos.to_a << "shop-cover-#{Time.now.to_i}#{File.extname(params['file'].path)}")
    @shop.update!(updated_at: Time.now.utc)
    File.open(params['file'].path, 'rb') { |file| Core::Storage.upload_file(@shop.shop_detail.aws_key_path(@shop.shop_detail.cover_photos.size - 1), file) }
    flash[:success] = 'Cover photo upload is successful'
    redirect_to shop_index_path(q: params['id'])
  end

  def delete_icon
    @shop.update!(icon: nil)
    flash[:success] = 'Icon deletion is successful'
    redirect_to shop_index_path(q: params['id'])
  end

  def delete_cover_photo
    if @shop.shop_detail.cover_photos.blank?
      flash[:danger] = 'Cover photo is already empty'
      return redirect_to shop_index_path(q: params['id'])
    end
    
    @shop.shop_detail.cover_photos.delete_at(params['index'].to_i)
    @shop.shop_detail.update!(cover_photos: @shop.shop_detail.cover_photos)
    @shop.update!(updated_at: Time.now.utc)
    flash[:success] = 'Cover photo deletion is successful'
    redirect_to shop_index_path(q: params['id'])
  end

  private

  def load_shop
    @shop = Shop.fetch_by_id(params['id'])
    if @shop.nil?
      render status: 400, json: { success: false, message: I18n.t('shop.not_found') }
      return
    end
  end
end
