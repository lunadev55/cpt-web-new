class StaticPagesController < ApplicationController
    before_action :set_s3_direct_post, only: [:partial,:deposit_form]
  def index
    flash.each do |f|
      f = nil
    end
  end
  
  def deposit_form
    @deposit = current_user.payment.find(params[:id])
  end
  
  def send_coin_confirmation
  end
  
  def withdrawal
    payment = Payment.find_by_hex(params[:code])
    if !payment.nil?
      payment.hex = ""
      discounted = ((BigDecimal(payment.volume,8)  * 0.99) - optax(payment.network)).truncate(8)
      response = Coinpayments.create_withdrawal(discounted, payment.network, payment.endereco, options = { auto_confirm: 1 })
      if response == "#{payment.network.upcase} is currently disabled!"
        flash[:info] = "Os saques para esta moeda estão temporáriamente desabilitados por motivos de instabilidade na rede! <br> Por favor, tente novamente mais tarde." 
      else
        payment.status = "complete"
        payment.txid = response.id
        p response
        if payment.save
          flash[:success] = "Transação enviada para o blockchain! "
        end
      end
    end
    redirect_to '/dashboard/index'
  end
  def partial
    @part = params[:partial]
    session[:current_place] = @part
    if params[:partial] == "editInfo"
      if current_user.nil?
        @user = User.new
      else
        @user = current_user
      end
    elsif params[:partial] == "overview"
      route = "/dashboard/overview/wallet/"
    elsif params[:partial] == "deposit"
      if current_user.active_request.any?
            flash[:danger] = "Você precisa esperar sua validação ser concluída para acessar essa área! "
            params[:partial] = "editInfo"
            @user = current_user
      else
            if check_user_documents
                flash[:danger] = "Você precisa ativar seu cadastro para utilizar esta função! "
                params[:partial] = "active"
                @request = current_user.active_request.new
            end
      end
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
      if current_user.active_request.any?
            flash[:danger] = "Você precisa esperar sua validação ser concluída para acessar essa área! "
            params[:partial] = "editInfo"
            @user = current_user
      else
            if check_user_documents
                flash[:danger] = "Você precisa ativar seu cadastro para utilizar esta função! "
                params[:partial] = "active"
                @request = current_user.active_request.new
            end
      end
      @currency = "BTC"
      @minimum = 0.001
      @tax = 0.0007
    elsif params[:partial] == "editSecurity"
      @user = current_user
    elsif params[:partial] == "business"
        if current_user.active_request.any?
            flash[:danger] = "Você precisa esperar sua validação ser concluída para acessar essa área! "
            params[:partial] = "editInfo"
            @user = current_user
        else
            if check_user_documents
                flash[:danger] = "Você precisa ativar seu cadastro para utilizar esta função! "
                params[:partial] = "active"
                @request = current_user.active_request.new
            end
        end
    elsif params[:partial] == "active"
      @request = current_user.active_request.new
    end
    
    
    render partial: "layouts/painelMenus"
  end

  private
    def set_s3_direct_post
      @s3_direct_post = S3_BUCKET.presigned_post(key: "uploads/#{SecureRandom.uuid}/${filename}", success_action_status: '201', acl: 'public-read')
    end
end
