class PagesController < ApplicationController
  def index

  end
  def send_coin_confirmation
  end
  def partial
    if params[:partial] == "editInfo"
      if current_user.nil?
        @user = User.new
      else
        @user = current_user
      end
    elsif params[:partial] == "deposit"
      @total = Hash.new
      @currency = "BTC"
      wallet = current_user.wallet.all
      wallet.each do |m|
          if @total["#{m.currency}"].nil?
              @total["#{m.currency}"] = 1
          else
              @total["#{m.currency}"] = @total["#{m.currency}"] + 1
          end
      end
    elsif params[:partial] == "depositHistory"
      @pays = current_user.payment.all.order(created_at: :desc).page params[:page]
    elsif params[:partial] == "withdrawal"
      @currency = "BTC"
      @minimum = 0.001
      @tax = 0.0007
    end
    
    render partial: "layouts/painelMenus"
  end
end