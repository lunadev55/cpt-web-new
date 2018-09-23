class ExchangeController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:cancel_order]
    def render_orders
        session[:currency1] = params[:coin1]
        session[:currency2] = params[:coin2]
    end
    
    def instant
        create_order(pair: params[:currency_base], amount: params[:amount], type: params[:type])
    end
    
    def deposit_new
        new_deposit = current_user.payment.new
        new_deposit.status = "incomplete"
        new_deposit.label = "deposit_operation"
        new_deposit.endereco = nil
        new_deposit.volume = params[:amount]
        new_deposit.network = "BRL"
        new_deposit.txid = nil
        new_deposit.op_id = nil
        new_deposit.hex = nil
        new_deposit.description = params[:method]
        if new_deposit.save
            flash[:info] = "Operação de depósito solicitada. Verifique detalhes na tabela a direita. "
        else 
            flash[:info] = "Algo deu errado. Por favor, tente novamente!. "
        end
    end
    
    def cancel_order(user=nil,prm=Hash.new)
        if prm['id'].nil?
            @userOrder = current_user
            id = params[:id]
        else
            @userOrder = user
            id = prm['id']
        end
        begin
            
            @order = @userOrder.exchangeorder.find(id)
        rescue
            return {error: 'Ordem não encontrada'}
        end
        
        inicial_order = @order
        par = @order.par.split('/')
        if (@order.status != "open") and (@order.status != "executada")
            return {error: 'Ordem já cancelada'}
        end
        @order.status = "cancelled"
        if prm['id'].nil?
            flash[:info] = "Ordem cancelada! "
            recent_orders = table_orders(@order.par,@order.tipo)
            array_compare = recent_orders[:table]
            if array_compare.include?(inicial_order)
                count = 0
                array = array_compare.to_a
                result = Array.new
                array.each do |k|
                    count += 1
                    if k != inicial_order
                        result << k
                    end
                end
                broadcast_order(@order,{order_list: result})
            end
        end
        
        
        case @order.tipo
        when "buy"
            amount = (BigDecimal(@order.amount,8) * BigDecimal(@order.price,8)).to_s
            id = add_saldo(@userOrder,par[1],amount,"cancel_buy")
            Payment.exchange_payment(@userOrder,id,par[1],amount,"cancel_buy",@order.par)
        when "sell"
            id = add_saldo(@userOrder,par[0],@order.amount,"cancel_sell")
            Payment.exchange_payment(@userOrder,id,par[0],@order.amount,"cancel_sell",@order.par)
        end
        @id = @order.id
        @order.save
        if !prm['id'].nil?
            return @order
        end
    end
    
    def table_orders(pair,type)
        resp = Hash.new
        case type
        when "buy"
            resp[:table] = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{pair}", tupe: "buy", stt: "open"}).order(price: :desc).limit(15)
        when "sell"
            resp[:table] = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{pair}", tupe: "sell", stt: "open"}).order(price: :asc).limit(15)
        when nil        
            resp[:bid] = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{pair}", tupe: "buy", stt: "open"}).order(price: :desc).limit(25)
            resp[:ask] = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{pair}", tupe: "sell", stt: "open"}).order(price: :asc).limit(25)
        end
        resp
    end
    

    def open_orders
        if session[:current_place] == "overview"
            render :json => json_last_price
        end
    end
    
    def pairExists(pair)
        EXCHANGE_PARES.each do |exnchange_pair|
            if pair.upcase == exnchange_pair.tr(" ","").upcase
                return true
            elsif "#{pair.split("/").last}/#{pair.split("/").first}" == exnchange_pair.tr(" ","").upcase
                return true
            end
        end
        return false
    end
    
    def create_order(*args)
        label_bool = true
        @paramers = params
        isApi = false
        if args.count >= 1
            isApi = true
            if current_user.nil?
                order = User.find(args[0][:user]).exchangeorder.new
            else
                order = current_user.exchangeorder.new
            end
            @paramers = Hash.new
            @paramers[:coin1] = args[0][:pair].tr(" ","").split("/")[0]
            @paramers[:coin2] = args[0][:pair].tr(" ","").split("/")[1]
            @paramers[:type] = args[0][:type]
            
            order.par = ("#{@paramers[:coin1]}/#{@paramers[:coin2]}").upcase
            if !(pairExists(order.par))
                return {error: 'Par não suportado'}
            end
            order.tipo = args[0][:type]
            amount_str = args[0][:amount].tr(",",".")
            total_amount_instant = "%0.8f" % amount_str
            order.amount = args[0][:amount]
            
            
            #Definição de preço, caso seja instant ou não
            if args[0][:price].nil?
                case args[0][:type]
                when "buy"
                    order_open = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: order.par, tupe: "sell", stt: "open"}).order(price: :asc).limit(1)[0]
                    if order_open.nil?
                        flash[:info] = "Não disponível. "
                        return
                    end
                    order.price = order_open.price
                    label_message = "comprar"
                    label_currency = @paramers[:coin1]
                when "sell"
                    order_open = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: order.par, tupe: "buy", stt: "open"}).order(price: :desc).limit(1)[0]
                    if order_open.nil?
                        flash[:info] = "Não disponível. "
                        return
                    end
                    order.price = order_open.price
                    label_message = "vender"
                    label_currency = @paramers[:coin2]
                end
                if BigDecimal(order_open.amount,8) < BigDecimal(order.amount,8)
                    order.amount = order_open.amount
                    label_bool = false
                    flash[:info] = "Você tentou #{label_message} mais #{label_currency} do que a ordem no preço indicado tinha disponível. Sua operação foi reajustada para a quantidade total disponível de #{order.amount} #{label_currency}. Caso queira realizar mais operações instantâneas neste par, utilize o formulário novamente. "
                end
            else
                order.price = args[0][:price]
                case args[0][:type]
                when "buy"
                    label_message = "comprar"
                    label_currency = @paramers[:coin1]
                when "sell"
                    label_message = "vender"
                    label_currency = @paramers[:coin2]
                end
            end
            order.status = "open"
        else
            
            @paramers
            order = parseOrder(@paramers)
        end
        if current_user.nil?
            user = User.find(args[0][:user])
            saldos = eval(get_saldo(user))
        else
            saldos = eval(get_saldo(current_user))
        end
        order.has_execution = false
        total_value = BigDecimal(order.amount,8) * BigDecimal(order.price,8)
        case @paramers[:type]
        when "buy"
            compare_value = total_value
            saldo = saldos[@paramers[:coin2]]
            discount_currency = @paramers[:coin2]
            operation = "exchange_buy"
            consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt AND price <= :preco", {str_par: order.par, tupe: "sell", stt: "open", preco: order.price}).order(price: :asc)
        when "sell"
            compare_value = order.amount
            saldo = saldos[@paramers[:coin1]]
            discount_currency = @paramers[:coin1]
            operation = "exchange_sell"
            consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt AND price >= :preco", {str_par: order.par, tupe: "buy", stt: "open", preco: order.price}).order(price: :desc)
        end
        if BigDecimal(saldo,8) >= BigDecimal(compare_value,8)
            if current_user.nil?
                id = add_saldo(user,discount_currency,compare_value.to_s,operation)
                Payment.exchange_payment(user,id,discount_currency,compare_value.to_s,"open_order_#{order.tipo}",order.par)
            else
                id = add_saldo(current_user,discount_currency,compare_value.to_s,operation)
                Payment.exchange_payment(current_user,id,discount_currency,compare_value.to_s,"open_order_#{order.tipo}",order.par)
            end
            
            
            
            check_active_orders(order,consulta_ordem_oposta,@paramers[:type])
            if isApi
                return order
            end
            if label_bool
                flash[:info] = "Ordem adicionada ao livro! "
            end
        else
            if !(args.count >= 1)
                flash[:info] = "Não há saldo para iniciar esta negociação "
            else
                return {error: "Não há saldo para iniciar esta negociação "}
            end
        end
        @order = order
    end
    
    private
    
    def json_last_price
        result = Hash.new
        EXCHANGE_PARES.each do |k|
            par = k.tr(" ", "")
            result["#{par}_buy"] = last_price(par,"buy","executada")
            result["#{par}_sell"] = last_price(par,"sell","executada")
        end
        result
    end
    
    def broadcast_order(order, *args)
        case order.status
        when "executada"
            percentage = price_percentage(order.par)
            executed = Exchangeorder.where("par = :str_par AND status = :stt", {str_par: order.par, stt: "executada"}).order("updated_at DESC").limit(20)
            ActionCable.server.broadcast 'last_orders',
                status: order.status,
                last_price: order.price,
                pair: order.par.tr("/","_"),
                orders: args[0][:order_list],
                opposite_orders: args[0][:opposite_orders],
                tipo: order.tipo,
                percentage_24h: percentage.tr(",","."),
                executed_list: executed
        when "cancelled", "open"
            ActionCable.server.broadcast 'last_orders',
                status: order.status,
                tipo: order.tipo,
                pair: order.par.tr("/","_"),
                orders: args[0][:order_list]
        else
            ActionCable.server.broadcast 'last_orders',
                status: order.status
        end
    end
    
    def check_active_orders(order,consulta_ordem_oposta,buysell)
        string_type = ""
        order_to_broadcast = order
        inicial_amount = BigDecimal(order.amount,8)
        current_amount = inicial_amount
        if consulta_ordem_oposta.empty?
            if order.save
                list = table_orders(order.par,order.tipo)[:table]
                if list.include?(order)
                    list_opposite = table_orders(order.par,order_type(order.tipo))[:table]
                    broadcast_order(order,{order_list: list,list_opposite: list_opposite})
                end
            end
            return 
        end
        consulta_ordem_oposta.each do |b|
            b_amount = BigDecimal(b.amount,8)
            o_amount = BigDecimal(order.amount,8)
            if BigDecimal(current_amount,8) > 0
                case order.tipo
                when "buy", "sell"
                    case 
                    when b_amount > o_amount
                        result_amount = b_amount - o_amount
                        saldo_sell = o_amount #saldo a adicionar pro comprador caso ordem parcelada
                        saldo_buy = o_amount
                        b.amount = result_amount.to_s #resultante do montante das duas ordens é o que sobra na transação do livro convertido em string
                        b.has_execution = true
                        b.save
                        
                        new = Exchangeorder.new
                        new.par = order.par
                        new.user_id = b.user_id
                        new.status = "executada"
                        new.price = b.price
                        new.amount = order.amount
                        new.tipo = order_type(order.tipo)
                        new.has_execution = true
                        if new.save
                            order_to_broadcast = new
                        end
                        
                        
                        current_amount = 0
                        order.status = "executora"
                        order.has_execution = true
                        order.save
                        broadcast_user_order = false
                    when o_amount >= b_amount
                        result_amount = o_amount - b_amount
                        saldo_sell = b_amount #saldo a adicionar pro comprador caso ordem parcelada de venda
                        saldo_buy = b_amount
                        
                        if result_amount > 0
                            order.has_execution = true
                            order.amount = result_amount
                        else
                            order.status = "executora"  
                        end
                        
                        b.status = "executada"
                        if b.save
                            order_to_broadcast = b
                        end
                        current_amount = result_amount
                        order.save
                        broadcast_user_order = true
                    end    
                end
                coin1 = order.par.split("/").first
                coin2 = order.par.split("/").last
                case order.tipo
                when "buy"
                    #adicionar saldo order.amount ao dono da order (compra)
                    saldo1 = exchange_tax(saldo_buy)
                    #p "adicionar saldo de #{saldo1} #{params[:coin1]} para #{User.find(order.user_id).first_name}"
                    saldo1_id = add_saldo(User.find(order.user_id),coin1,saldo1,"exchange_credit")
                    Payment.exchange_payment(User.find(order.user_id),saldo1_id,coin1,saldo1,"#{order.tipo}_order_execution",order.par)
                    #adicionar saldo b.amount * b.price ao dono da b (compra)
                    saldo2 = exchange_tax(BigDecimal((saldo_buy * BigDecimal(b.price,8))))
                    #p "adicionar saldo de #{saldo2} #{params[:coin2]} para #{User.find(b.user_id).first_name}"
                    saldo2_id = add_saldo(User.find(b.user_id),coin2,saldo2,"exchange_credit")
                    Payment.exchange_payment(User.find(b.user_id),saldo2_id,coin2,saldo2,"#{b.tipo}_order_execution",b.par)
                    string_type = "sell"
                when "sell"
                    
                    coin2_sell_price = exchange_tax(BigDecimal(saldo_sell,8) * BigDecimal(b.price,8))
                    #p "adicionar saldo de #{BigDecimal(coin2_sell_price,8)} #{coin2} para #{User.find(order.user_id).first_name}"
                    coin2_sell_id = add_saldo(User.find(order.user_id),coin2,BigDecimal(coin2_sell_price,8),"exchange_credit")
                    Payment.exchange_payment(User.find(order.user_id),coin2_sell_id,coin2,BigDecimal(coin2_sell_price,8).to_s,"#{order.tipo}_order_execution",order.par)
                    
                    coin1_sell_price = exchange_tax(saldo_sell)
                    #p "adicionar saldo de #{coin1_sell_price} #{coin1} para #{User.find(b.user_id).first_name}"
                    coin1_sell_id = add_saldo(User.find(b.user_id),coin1,coin1_sell_price,"exchange_credit")
                    Payment.exchange_payment(User.find(b.user_id),coin1_sell_id,coin1,coin1_sell_price,"#{b.tipo}_order_execution",b.par)
                    string_type = "buy"
                end
            end
        end
        list = table_orders(order.par,string_type)[:table]
        list_opposite = table_orders(order.par,order_type(string_type))[:table]
        broadcast_order(order_to_broadcast,{order_list: list, opposite_orders: list_opposite})
        #head :ok
    end
    
    def order_type(arg)
        if arg == "buy"
            'sell'
        else
            'buy'
        end
    end
    
    def parseOrder(prms)
        new_order = current_user.exchangeorder.new
        new_order.par = "#{prms[:coin1]}/#{prms[:coin2]}"
        new_order.tipo = prms[:type]
        new_order.amount = prms[:amount]
        new_order.price = prms[:price]
        new_order.status = "open"
        new_order
    end
end
