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
                case payment.label.downcase
                when "saque"
                    payment.hex = ""
                    payment.save
                    add_saldo(current_user,payment.network,payment.volume,"withdrawal_cancel")
                    flash[:success] = "Saque cancelado. "
                else
                    payment.save
                    flash[:success] = "Depósito cancelado. "
                end
            else
                flash[:success] = "Operação já realizada ou cancelada. "
            end
        else
            flash[:success] = "Operação não encontrada. "
        end
    end
    
    def contact_email
        user = User.find_by_email('ricardo.malafaia1994@gmail.com')
        text = "Usuário #{params[:name]} (#{params[:email]}) escreveu: <br> #{params[:message]}"
        title = "Email de contato para suporte"
        deliver_generic_email(user,text,title)
        flash[:success] = "Mensagem enviada para o suporte!"
    end
    
    def withdrawal_coin
        payment = current_user.payment.new
        payment.network = params[:currency]
        payment.endereco = params[:destiny]
        payment.volume = params[:amount]
        payment.description = params[:description]
        saldo = eval(get_saldo(current_user))
        if  BigDecimal(saldo["#{payment.network}"],8) > BigDecimal(payment.volume,8)
            payment.label = "Saque"
            payment.status = "incomplete"
            payment.hex = SecureRandom.hex
            payment.op_id = add_saldo(current_user,payment.network,payment.volume,"withdrawal")
            payment.save
            comission = (BigDecimal(payment.volume,8) * 0.01).truncate(8)
            discounted = BigDecimal(payment.volume,8) - comission - optax(payment.network)
            text = "Olá #{current_user.first_name.capitalize} #{current_user.last_name.capitalize}. <br>
            Você iniciou um processo de <b>saque</b> em sua conta na Cripto Câmbio Exchange.<br>
            Verifique abaixo os dados do saque e clique no link abaixo para confirmar:<br>
            Nota: <b>Se você não iniciou este processo você deve fazer uma recuperação de senha imediata, pois quem o iniciou tem sua senha correta.</b><br>
            Volume total: <b> #{payment.volume} #{payment.network}</b><br>
            Comissão: <b>#{comission.to_s}</b><br>
            Taxa de operação: <b>#{optax(payment.network)}</b><br>
            Volume a sacar:<b> #{discounted}</b><br>
            <a href='http://cptcambio/withdrawal/#{payment.hex}'>Clique aqui</a> para concluir o saque.
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
        wallets = current_user.wallet.where("currency = :cur", {cur: params[:currency]})
        if wallets.size >= 5
            flash[:success] = "Você já possui 5 endereços de carteira nesta moeda! "
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
        flash[:success] = "Endereço #{params[:currency]} gerado com sucesso!"
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
                            if payment.op_id == nil #realizar update
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
            @minimum = 0.002
            @tax = 0.0012
        elsif @currency == "BRL"
            @minimum = 30
        elsif @currency == "XMR"
            @minimum = 0.02
            @tax = 0.01
        elsif @currency == "DASH"
            @minimum = 0.002
            @tax = 0.001
        elsif @currency == "BCH"
            @minimum = 0.001
            @tax = 0.0002
        end
    end
    def payments_details
        @payments = current_user.payment.where("status = :status_type",  {status_type: "incomplete"}).page params[:page]
    end
end
