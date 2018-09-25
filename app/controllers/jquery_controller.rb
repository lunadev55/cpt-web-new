class JqueryController < ApplicationController
    require 'rubygems'
    skip_before_action :verify_authenticity_token, :only => [:coinpayments_deposit, :cancel_withdrawal]
    def dashboard_options
        if params[:partial] == "editInfo"
            editInfo
        elsif params[:partial] == "deposit"
            deposit
        elsif params[:partial] == "depositHistory"
            get_payments
        elsif params[:partial] == "withdrawal"
            withdrawal_coin
        elsif params[:partial] == "myOrders"
            myOrders
        end
    end
    
    def myOrders
        pair = params[:params].tr("_","/")
        @orders = (current_user.exchangeorder.where("par = :par AND status = 'open'", {par: pair})).order(created_at: :desc).page params[:page]
        render 'my_order_result'
    end
    
    def cancel_withdrawal
        payment = current_user.payment.find(params[:id])
        if !payment.nil?
            if payment.status == "incomplete"
                payment.status = "canceled"
                case payment.label.downcase
                when "saque"
                    payment.hex = ""
                    payment.save
                    add_saldo(current_user,payment.network,payment.volume,"withdrawal_cancel")
                    flash[:info] = "Saque cancelado. "
                else
                    payment.save
                    flash[:info] = "Depósito cancelado. "
                end
            else
                flash[:info] = "Operação já realizada ou cancelada. "
            end
        else
            flash[:info] = "Operação não encontrada. "
        end
    end
    
    def contact_email
        user = User.find_by_email('ricardo.malafaia1994@gmail.com')
        text = "Usuário #{params[:name]} (#{params[:email]}) escreveu: <br> #{params[:message]}"
        title = "Email de contato para suporte"
        deliver_generic_email(user,text,title)
        flash[:info]= "Mensagem enviada para o suporte!"
    end
    
    def withdrawal_coin
        payment = current_user.payment.new
        payment.network = params[:currency]
        payment.endereco = params[:destiny]
        payment.volume = params[:amount]
        payment.description = params[:description]
        saldo = eval(get_saldo(current_user))
        volume_dec = BigDecimal(payment.volume,8)
        comission = ((volume_dec * 0.005) + optax(payment.network)).round(8)
        required_amount = (volume_dec + comission).round(8)
        if  BigDecimal(saldo["#{payment.network}"],8) > required_amount
            payment.label = "Saque"
            payment.status = "incomplete"
            payment.hex = SecureRandom.hex
            payment.op_id = add_saldo(current_user,payment.network,required_amount,"withdrawal")
            payment.save
            text = "Olá #{current_user.first_name.capitalize} #{current_user.last_name.capitalize}. <br>
            Você iniciou um processo de <b>saque</b> em sua conta na Cripto Câmbio Exchange.<br>
            Verifique abaixo os dados do saque e clique no link abaixo para confirmar:<br>
            Nota: <b>Se você não iniciou este processo você deve fazer uma recuperação de senha imediata, pois quem o iniciou tem sua senha correta.</b><br>
            Volume total: <b> #{required_amount.to_s} #{payment.network}</b><br>
            Comissão: <b>#{comission.to_s}</b><br>
            Volume a sacar:<b> #{payment.volume}</b><br>
            <a href='https://www.cptcambio.com/withdrawal/#{payment.hex}'>Clique aqui</a> para concluir o saque.
            "
            deliver_generic_email(current_user,text,"Confirmação de saque")
            flash[:info] = "Pedido de saque realizado! Verifique seu email. "
        else
            flash[:info] = "Saldo Insuficiente! "
        end
        render 'withdrawal_form_result'
    end
    
    def get_payments
        if params[:end] != nil && params[:end] != ""
            date_final = Date.parse(params[:end])
        else
            date_final = Time.now.to_s
        end
        if params[:dateInicial] == "week"
            data_inicial = (Date.today-7).to_s
        elsif params[:dateInicial] == "month"
            data_inicial = (Date.today-30).to_s
        elsif params[:begin] != nil && params[:begin] != ""
            data_inicial = Date.parse(params[:begin])
        else
            data_inicial = Date.today.to_s
        end
        if params[:currency] == "ALL"
            if params[:dateInicial] == nil && params[:begin] == nil
                @pays = current_user.payment.all.order(created_at: :desc).page params[:page]
            else
                @pays = current_user.payment.where('created_at BETWEEN ? AND ?', data_inicial.to_s, date_final.to_s).order(created_at: :desc).page params[:page]
            end
        else
            if params[:dateInicial] == nil && params[:begin] == nil
                @pays = current_user.payment.where(network: params[:currency]).order(created_at: :desc).page params[:page]
            else
                @pays = current_user.payment.where('network = ? AND created_at BETWEEN ? AND ?', params[:currency], data_inicial.to_s, date_final.to_s).order(created_at: :desc).page params[:page]
            end
        end
    end
    
    def get_wallets
        if params[:currency].nil?
            params[:currency] = "BTC"
        end
        @wallet = current_user.wallet.where(currency: params[:currency]).page params[:page]
        @qrs = []
        @wallet.each do |w|
            @qrs << RQRCode::QRCode.new("#{w.currency.downcase}:#{w.address}") 
        end
    end
    
    def editInfo
        @user = User.find(params['user_id'])
        login_hash = Hash.new
        login_hash['email'] = @user.email 
        login_hash['password'] = params["password"]
        
        if @user == current_user
            if params['first_name'] != current_user.first_name
                @user.first_name = params['first_name']
            end
            if params['last_name'] != current_user.last_name
                @user.last_name = params['last_name']
            end
            if params['email'] != current_user.email
                @user.email = params['email']
            end
            if params['username'] != current_user.username
                @user.username = params['username']
            end
            if params['birth'] != current_user.birth
                @user.birth = params['birth']
            end
            if params['document'] != current_user.document
                @user.document = params['document']
            end
            if params['password'] == params['password_confirmation']
                @user_session = UserSession.new(login_hash)
                if @user_session.save
                    @user.save
                    cpt_update_user(@user)
                    flash[:info] = "Informações atualizadas!"
                else
                    flash[:info] = "Senha incorreta!"
                end
            else
                flash[:info] = "Senhas Não coincidem!"
            end
            return
        end
    end
    
    def deposit
        wallets = current_user.wallet.where("currency = :cur", {cur: params[:currency]})
        if wallets.size >= 5
            flash[:info] = "Você já possui 5 endereços de carteira nesta moeda! "
            return
        end
        transaction = Coinpayments.get_callback_address(params[:currency], options = { ipn_url: "https://#{ENV['BASE_URL']}/#{ENV['COINPAYMENTS_ROUTE']}"})
        @endereco = transaction.address
        wal = current_user.wallet.new
        wal.address = @endereco
        wal.currency = params[:currency]
        if params[:currency] == "XMR"
            wal.dest_tag = transaction.dest_tag
        end
        wal.save
        get_wallets
        flash[:info] = "Endereço #{params[:currency]} gerado com sucesso!"
    end
    
    def coinpayments_deposit
        if params["merchant"] == ENV["COINPAYMENT_ID"]
            p "merchant validado"
            if params["status"] == "0" #esperando receber
                p "depósito a caminho"
            elsif params["status"] == "-1" #cancelado
                p "cancelado"
            elsif params["status"] == "1" #pendente
                p "pendente"
            elsif params["status"] == "2" #completo
                p "completo"
            elsif params["status"] == "100" #creditar depósito
                p "finalizado"
                if params["ipn_type"] == "deposit" && params["status_text"] == "Deposit confirmed"
                    p "operacao validada"
                    wallet = Wallet.find_by_address(params["address"])
                    if !wallet.nil?
                        p "carteira validada"
                        user = User.find(wallet.user_id)
                        payment = Payment.find_by_txid(params["txn_id"])
                        if payment.nil? && !user.nil? 
                            p "usuario validado"
                            pay = user.payment.new
                            pay.status = "incomplete"
                            pay.label = "deposit"
                            pay.endereco = wallet.address
                            pay.volume = params["amount"]
                            pay.network = params["currency"]
                            pay.txid = params["txn_id"]
                            savePayment(pay,pay.volume,user)
                        else #pagamento já existe
                            if payment.op_id == nil #realizar update
                                savePayment(payment,payment.volume,user)
                            end
                        end
                    end
                end
            end
        end
        render status: :ok
    end
    
    def savePayment(pay,discounted,user)
        if pay.save
            if pay.op_id == nil
                pay.op_id = add_saldo(user,pay.network,discounted,"deposit")
                pay.status = "complete"
                pay.save
                deliver_deposit_email(user,pay.network,pay.volume,discounted)
                
            else
                pay.status = "complete"
                pay.save
            end
        end
    end
    
    def render_payment
        @payment = current_user.payment.find(params[:id])
        @href = blocker_link(@payment.network)
    end
    
    def render_withdrawal_details
        @payment = current_user.payment.find(params[:id])
    end
    
    def withdrawal_get
        @currency = params[:currency]
        @minimum = ((TAXES[params[:currency]].to_f) * 2).round(8)
        @tax = TAXES[params[:currency]].to_f
    end
    def payments_details
        @payments = current_user.payment.where("status = :status_type",  {status_type: "incomplete"}).page params[:page]
    end
end
