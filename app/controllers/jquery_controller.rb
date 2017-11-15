class JqueryController < ApplicationController
    require 'rubygems'
    skip_before_action :verify_authenticity_token, :only => [:coinpayments_deposit]
    def dashboard_options
        if params[:partial] == "editInfo"
            editInfo
        elsif params[:partial] == "deposit"
            deposit
        elsif params[:partial] == "depositHistory"
            get_payments
        end
    end
    
    def get_payments
        if params[:end] != nil && params[:end] != ""
            date_final = Date.parse(params[:end])
        else
            date_final = Date.today.to_s
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
                @pays = current_user.payment.all.page params[:page]
            else
                @pays = current_user.payment.all.where('created_at BETWEEN ? AND ?', data_inicial.to_s, date_final.to_s).page params[:page]
            end
        else
            if params[:dateInicial] == nil && params[:begin] == nil
                @pays = current_user.payment.where(network: params[:currency]).page params[:page]
            else
                @pays = current_user.payment.all.where('network = ? AND created_at BETWEEN ? AND ?', params[:currency], data_inicial.to_s, date_final.to_s).page params[:page]
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
                                p pay_discount.to_string
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
            pay.op_id = add_saldo(user,pay.network,discounted,"deposit")
            if pay.op_id != nil
                p "saldo adicionado"
                deliver_deposit_email(user,pay.network,pay.volume,discounted)
                pay.status = "complete"
                pay.save
            end
        end
    end
    
    def payments_details
        @payments = Payment.where("status = :status_type AND user_id = :user",  {status_type: "open", user: current_user.id })
    end
end
