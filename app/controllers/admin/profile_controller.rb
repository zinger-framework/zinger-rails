class Admin::ProfileController < AdminController
  before_action :set_title

  def index
    @title = 'Profile'
  end

  def set_title
    @header = { links: [] }
  end
end
