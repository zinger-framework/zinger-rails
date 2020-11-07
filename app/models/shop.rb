class Shop < ApplicationRecord
  STATUSES = { 'ACTIVE' => 1, 'BLOCKED' => 2 }

  default_scope { where(status: STATUSES['ACTIVE'], deleted: false) }
  searchkick word_start: ['name'], locations: ['location'], default_fields: ['status', 'deleted']

  has_one :shop_detail

  def search_data
    { name: self.name, location: { lat: self.lat, lon: self.lng }, tag: self.tag }
  end

  def as_json purpose = nil
    case purpose
    when 'ui_shop'
      return { 'id' => self.id, 'name' => self.name, 'icon' => self.icon, 'tags' => self.tag.split(' '),
        'area' => self.shop_detail.address['area'] }
    when 'ui_shop_detail'
      return { 'id' => self.id, 'name' => self.name, 'icon' => self.icon, 'tags' => self.tag.split(' ') }
        .merge(self.shop_detail.as_json('ui_shop_detail'))
    end
  end
end
