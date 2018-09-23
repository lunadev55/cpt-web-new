class ApiController < ApplicationController
    before_action :check_api_keys
    skip_before_action :verify_authenticity_token, only: [:check_api_keys,:proxyRequest]
    skip_before_action :check_api_keys, only: [:test_address,:instant_buy_price,:generate_api_key,:delete_api_key,:login]
    
    def check_api_keys
        iv = request.headers["key"]
        key = request.headers["secret"]
       
        
        @key = ApiInfo.find_by_key("#{iv}")
        if !@key.nil?
            decipher = OpenSSL::Cipher::AES.new(128, :CBC)
            decipher.decrypt
            decipher.iv = (Base64.strict_decode64(iv))
            send_secret = (Base64.strict_decode64(key))
            real_secret = (Base64.strict_decode64(@key.secret))
            if send_secret == real_secret
                @user = (User.find(@key.user_id))
                decipher.key = (Base64.decode64(key))
                if !params[:digest].nil?
                    tempMessage = Base64.strict_decode64(params[:digest])
                    decrypt = decipher.update(tempMessage)
                    decrypt << decipher.final()
                    @message = JSON.parse(decrypt)
                end
            else
                render json: {error: "Chaves de API inválidas."}
            end
        else
            render json: {error: "Chaves de API inválidas."}
        end
    end
    
    def proxyRequest
        case params[:method]
        when 'userInfo'
            saldo = get_saldo(@user).to_str
            render json: (@user.as_json).merge!({balance: saldo.as_json})
        when 'list_orders'
            if @message[:limit].nil?
                list_orders
            else
                if BigDecimal(@message[:limit]) > 100
                    list_orders(100)
                else
                    list_orders(@message[:limit])
                end
                
            end
        when 'send_order'
            send_order
        when 'cancel_order'
            cancel_order
        when 'list_deposits'
            if @message["limit"].nil?
                list_deposits
            else
                if BigDecimal(@message["limit"]) > 100
                    list_deposits(100)
                else
                    list_deposits(@message["limit"])
                end
            end
        when "list_withdrawals"
            if @message["limit"].nil?
                list_withdrawals
            else
                if BigDecimal(@message["limit"]) > 100
                    list_withdrawals(100)
                else
                    list_withdrawals(@message["limit"])
                end
            end
        when "list_history"
            if !@message["limit"].nil?
                if BigDecimal(@message["limit"]) > 100
                    @message["limit"] = 100
                end
                if @message["pair"].nil?
                    list_history(@message["limit"])
                else
                    list_history(@message["limit"],@message["pair"].upcase)
                end
            else
                list_history
            end
        when "instant_buy_price"
            instant_buy_price
        when "list_pairs"
            list_pairs
        when "orderbook"
            orderbook
        else
            render json: {error: "Método não encontrado."}
        end
    end
    
    def orderbook
        controller = ExchangeController.new
        resp = Hash.new
        resp[:pairs] = Array.new
        EXCHANGE_PARES.each do |pair|
            resp[:pairs] << pair.tr(" ","")
        end
        input_coin = @message["pair"].split("/").first
        output_coin = @message["pair"].split("/").last
        result = Hash.new
        resp[:pairs].each do |pair_cpt|
            if (@message["pair"].upcase == pair_cpt)
                result = controller.table_orders(@message["pair"].upcase,nil)
                break
            elsif ("#{output_coin.upcase}/#{input_coin.upcase}" == pair_cpt)
                result = controller.table_orders("#{output_coin.upcase}/#{input_coin.upcase}".upcase,nil)
                break
            end
        end
        render json: result 
    end
    
    def list_pairs
        resp = Hash.new
        resp[:pairs] = Array.new
        EXCHANGE_PARES.each do |pair|
            resp[:pairs] << pair.tr(" ","")
        end
        render json: resp
    end
    
    def list_orders(limit=25)
        render json: @user.exchangeorder.order("id DESC").take(limit)
    end
    
    def send_order
        exchange = ExchangeController.new
        result = exchange.create_order(pair: @message["currency_base"], amount: @message["amount"], price: @message["price"], type: @message["type"], user: @user.id)
        render json: result
    end
    
    def cancel_order #{id => x}
        exchange = ExchangeController.new
        render json: exchange.cancel_order(@user,@message)
    end
    
    def list_deposits(limit=25)
        render json: @user.payment.where("label = :lb", {lb: 'deposit'}).order("id DESC").take(limit)
    end
    
    def list_withdrawals(limit=25)
        jso = @user.payment.where("label = :lb", {lb: 'Saque'}).order("id DESC").take(limit)
        if jso.empty?
            render json: {error: 'Não há saques para esse usuário'}
        else
            render json: jso
        end
    end
    
    def list_history(limit=25,par=nil)
        validate = ExchangeController.new
        if par.nil?
            jeyson = Exchangeorder.where("status = :stt", {stt: "executada"}).order("updated_at DESC").limit(limit)
        else
            if validate.pairExists(par.upcase)
                jeyson = Exchangeorder.where("par = :str_par AND status = :stt", {str_par: "#{par}", stt: "executada"}).order("updated_at DESC").limit(limit)
            else
                render json: {error: "Este par não existe."} and return
            end
        end
        render json: jeyson
    end
    
    def test_address
        currency = params[:currency]
        address = params[:address]
        case currency
        when "ETH"
            regex = /^0x[a-fA-F0-9]{40}$/
            result = address.match(regex)
            if !(result.nil?)
                render :text => "true"
            else
                render :text => "false"
            end
        end
    end
    
    def instant_buy_price
        if params[:tipo] == "buy"
            a = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{params[:coin1]}/#{params[:coin2]}", tupe: "sell", stt: "open"}).order(price: :asc).limit(1)
        else
            a = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{params[:coin1]}/#{params[:coin2]}", tupe: "buy", stt: "open"}).order(price: :desc).limit(1)
        end
        session[:currency1] = params[:coin1]
        session[:currency2] = params[:coin2]
        if a.empty?
            render plain: "Não disponível."
        else
            render plain: "#{a[0].price} #{params[:coin2]}"
        end
    end
    
    def generate_api_key
        @message_response = ""
        cipher =  OpenSSL::Cipher.new('AES-128-CBC')
        cipher.encrypt
        
        key = cipher.random_key
        iv = cipher.random_iv
        
        apiKey = current_user.apiInfo.new
        apiKey.key = (Base64.strict_encode64(iv))
        apiKey.secret = (Base64.strict_encode64(key))
       
        if apiKey.save
            @keys = current_user.apiInfo.all
            @message_response << "Confira abaixo suas chaves: <br>"
            @message_response << "Chave: <b>#{apiKey.key}</b><br>"
            @message_response << "Chave Secreta: <b>#{apiKey.secret}</b><br>"
            @message_response << "<b class='red'>A chave secreta jamais será exibida novamente</b> e não haverá formas de recuperação. Salve sua chave em um local seguro.<br> As chaves de API são usadas para integrar serviços e softwares com as funcionalidades do nosso sistema."
        end
    end
    
    def test_enviar
        params = Hash.new
        params[:coin1] = "LTC"
        params[:coin2] = "BTC"
        params[:tipo] = "buy"
        key = "pqWLVxov3816MHrhtiz0kQ=="
        secret = "pPA5GsDnpBVcBiFNc1L8fw=="
        
        cipher = OpenSSL::Cipher.new('AES-128-CBC')
        cipher.encrypt # We are encypting
        # The OpenSSL library will generate random keys and IVs
        cipher.key = Base64.strict_decode64(secret)
        cipher.iv = Base64.strict_decode64(key)
        headers = {
                    "key" => key,
                    "secret" => secret,
        }
        url = URI.parse("https://cpt-cambio-new-rbm4.c9users.io/api/instant_buy_price/")
        req = Net::HTTP::Post.new(url.request_uri, initheader = headers)
        message = cipher.update(params.to_json) + cipher.final
        
        params = Hash.new
        params[:digest] = Base64.strict_encode64(message)
        req.set_form_data(params)
        
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == "https")
        response = http.request(req)
        begin
            p JSON.parse(response.body)
        rescue
            p response.body
        end
        
    end
    def delete_api_key
        key = current_user.apiInfo.where("id = :ky", {ky: params[:key]})
        if !key.nil? and !key.empty?
            key.first.delete
        end
        @keys = current_user.apiInfo.all
        render 'generate_api_key'
    end
    
    
    def login(params)
        user_session = UserSession.new(params)
        if user_session.save
          return true
        else
          return false
        end
    end
end
