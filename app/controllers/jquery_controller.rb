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
        end
    end
    
    def cancel_withdrawal
        payment = current_user.payment.find(params[:id])
        if !payment.nil?
            if payment.status == "incomplete"
                payment.status = "canceled"
                payment.save
                add_saldo(current_user,payment.network,payment.volume,"withdrawal_cancel")
                flash[:success] = "Saque cancelado. "
            else
                flash[:success] = "Saque já realizado ou cancelado. "
            end
        else
            flash[:success] = "Operação não encontrada. "
        end
    end
    
    def optax(currency)
        case currency
        when "BTC"
            return 0.0007
        when "ETH"
            return 0.0007
        when "LTC"
            return 0.001
        when "DOGE"
            return 1
        when "BRL"
            return 0
        end
    end
    
    def withdrawal_coin
        payment = current_user.payment.new
        payment.network = params[:currency]
        payment.endereco = params[:destiny]
        payment.volume = params[:amount]
        saldo = eval(get_saldo(current_user))
        if saldo["#{payment.network}"] > BigDecimal(payment.volume,8)
            payment.label = "Saque"
            payment.status = "incomplete"
            payment.op_id = add_saldo(current_user,payment.network,payment.volume,"withdrawal")
            payment.save
            comission = (BigDecimal(payment.volume,8) * 0.01).truncate(8)
            text = "Olá #{current_user.first_name.capitalize} #{current_user.last_name.capitalize}. <br>
            Você iniciou um processo de <b>saque</b> em sua conta na Cripto Câmbio Exchange.<br>
            Verifique abaixo os dados do saque e clique no link abaixo para confirmar:<br>
            Nota: <b>Se você não iniciou este processo você deve fazer uma recuperação de senha imediata, pois quem o iniciou tem sua senha correta.</b><br>
            Volume total: #{payment.volume} <b>#{payment.network}</b><br>
            Comissão: #{comission.to_s}<br>
            Taxa de operação: #{optax(payment.network)}<br>
            Volume a sacar:
            "
            deliver_generic_email(current_user,text,"Confirmação de saque")
            flash[:success] = "Pedido de saque realizado! Verifique seu email. "
        else
            flash[:success] = "Saldo Insuficiente! "
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
        p @wallet.nil?
    end
    def editInfo
        @user = User.find(params['user_id'])
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
                @user_session = UserSession.new(params)
                if @user_session.save
                    @user.save
                    cpt_update_user(@user)
                    flash[:success] = "Informações atualizadas!"
                else
                    flash[:success] = "Senha incorreta!"
                end
            else
                flash[:success] = "Senhas Não coincidem!"
            end
            return
        end
    end
    
    def deposit
        transaction = Coinpayments.get_callback_address(params[:currency], options = { ipn_url: "http://www.#{ENV['BASE_URL']}/#{ENV['COINPAYMENTS_ROUTE']}"})
        @endereco = transaction.address
        wal = current_user.wallet.new
        wal.address = @endereco
        wal.currency = params[:currency]
        wal.save
        flash[:success] = "Endereço #{params[:currendy]} gerado com sucesso!"
        p @endereco
    end
    
    def coinpayments_deposit
        p "inicio"
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
                        p payment
                        if payment.nil? && !user.nil? 
                            p "usuario validado"
                            pay = user.payment.new
                            pay.status = "incomplete"
                            pay.label = "deposit"
                            pay.endereco = wallet.address
                            pay.volume = params["amount"]
                            pay.network = params["currency"]
                            pay.txid = params["txn_id"]
                            pay_discount = BigDecimal(pay.volume,8) * BigDecimal(0.01,2)
                            discounted = (BigDecimal(pay.volume,8) - pay_discount).truncate(8)
                            savePayment(pay,discounted,user)
                        else #pagamento já existe
                            if payment.status == "incomplete" && payment.op_id == nil #realizar update
                                pay_discount = BigDecimal(payment.volume,8) * BigDecimal(0.01,2)
                                discounted = (BigDecimal(payment.volume,8) - pay_discount).truncate(8)
                                savePayment(payment,discounted,user)
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
        if @currency == "LTC"
            @minimum = 0.01
            @tax = 0.001
        elsif @currency == "BTC"
            @minimum = 0.001
            @tax = 0.0007
        elsif @currency == "DOGE"
            @minimum = 5
            @tax = 1
        elsif @currency == "ETH"
            @minimum = 0.001
            @tax = 0.0007
        elsif @currency == "BRL"
            @minimum = 30
        end
    end
    def payments_details
        @payments = Payment.where("status = :status_type AND user_id = :user",  {status_type: "incomplete", user: current_user.id }).page params[:page]
    end
end
