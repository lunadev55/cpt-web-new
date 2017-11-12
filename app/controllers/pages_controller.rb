class PagesController < ApplicationController
  def index

  end
  def partial
    if params[:partial] == "editInfo"
      if current_user.nil?
        @user = User.new
      else
        @user = current_user
      end
    end
    render partial: "layouts/painelMenus"
  end
end