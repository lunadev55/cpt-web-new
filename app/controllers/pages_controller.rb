class PagesController < ApplicationController
  def index

  end
  def send_coin_confirmation
  end
  def withdrawal
    payment = Payment.find_by_hex(params[:code])
    if !payment.nil?
      payment.hex = ""
      discounted = ((BigDecimal(payment.volume,8)  * 0.99) - optax(payment.network)).truncate(8)
      response = Coinpayments.create_withdrawal(discounted, payment.network, payment.endereco, options = { auto_confirm: 1 })
      payment.status = "complete"
      payment.txid = response.id
      p response
      if payment.save
        flash[:success] = "Transação enviada para o blockchain! "
      end
    end
    redirect_to '/dashboard/index'
  end
  def partial
    session[:current_place] = params[:partial]
    if params[:partial] == "editInfo"
      if current_user.nil?
        @user = User.new
      else
        @user = current_user
      end
    elsif params[:partial] == "overview"
      route = "/dashboard/overview/wallet/"
      
    
    
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
    elsif params[:partial] == "editSecurity"
      @user = current_user
    end
    
    render partial: "layouts/painelMenus"
  end
end