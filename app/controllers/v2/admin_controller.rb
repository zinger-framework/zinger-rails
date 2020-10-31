class V2::AdminController < ApiController
  skip_before_action :authenticate_request, :check_origin

  def dashboard
    @title = 'Dashboard'
  end
end
