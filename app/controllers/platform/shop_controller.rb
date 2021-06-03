class Platform::ShopController < PlatformController
  before_action :load_shop

  def show
    render status: 200, json: { success: true, message: 'success', data: { shop: @shop.as_json('platform_shop') } }
  end

  def update
    # TODO: Add update code changes - Logesh
    render status: 200, json: { success: true, message: I18n.t('shop.update_success'), data: { shop: @shop.as_json('platform_shop') } }
  end

  def destroy
    if @shop.deleted
      render status: 400, json: { success: false, message: I18n.t('shop.delete_failed') }
      return
    end

    @shop.update!(deleted: true)
    render status: 200, json: { success: true, message: I18n.t('shop.delete_success') }
  end

  private

  def load_shop
    @shop = Shop.unscoped.find_by_id(params['id'])
    if @shop.nil?
      render status: 404, json: { success: false, message: I18n.t('shop.not_found') }
      return
    end
  end
end
