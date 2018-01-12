class ExchangeController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:cancel_order]
    def render_orders
        session[:currency1] = params[:coin1]
        session[:currency2] = params[:coin2]
    end
    
    def instant
        create_order(pair: params[:currency_base], amount: params[:amount], type: params[:type])
    end
    def cancel_order
        @order = current_user.exchangeorder.find(params[:id])
        inicial_order = @order
        par = @order.par.split('/')
        if (@order.status != "open") and (@order.status != "executada")
            return
        end
        @order.status = "cancelled"
        flash[:success] = "Ordem cancelada! "
        recent_orders = table_orders(@order.par,@order.tipo)
        case @order.tipo
        when "buy"
            amount = (BigDecimal(@order.amount,8) * BigDecimal(@order.price,8)).to_s
            id = add_saldo(current_user,par[1],amount,"cancel_buy")
            Payment.exchange_payment(current_user,id,par[1],amount,"cancel_buy",@order.par)
        when "sell"
            id = add_saldo(current_user,par[0],@order.amount,"cancel_sell")
            Payment.exchange_payment(current_user,id,par[0],@order.amount,"cancel_sell",@order.par)
        end
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
        @order.save
    end
    def table_orders(pair,type)
        resp = Hash.new
        case type
        when "buy"
            resp[:table] = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{pair}", tupe: "buy", stt: "open"}).order(price: :desc).limit(15)
        when "sell"
            resp[:table] = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{pair}", tupe: "sell", stt: "open"}).order(price: :asc).limit(15)
        end
        resp
    end
    def open_orders
        if session[:current_place] == "overview"
            render :json => json_last_price
        end
    end
    
    def create_order(*args)
        label_bool = true
        if args.count >= 1
            order = current_user.exchangeorder.new
            params[:coin1] = args[0][:pair].tr(" ","").split("/")[0]
            params[:coin2] = args[0][:pair].tr(" ","").split("/")[1]
            order.par = "#{params[:coin1]}/#{params[:coin2]}"
            order.tipo = args[0][:type]
            total_amount_instant = args[0][:amount]
            order.amount = args[0][:amount]
            case args[0][:type]
            when "buy"
                order_open = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: order.par, tupe: "sell", stt: "open"}).order(price: :asc).limit(1)[0]
                if order_open.nil?
                    flash[:success] = "Não disponível. "
                    return
                end
                order.price = order_open.price
                label_message = "comprar"
                label_currency = params[:coin1]
            when "sell"
                order_open = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: order.par, tupe: "buy", stt: "open"}).order(price: :desc).limit(1)[0]
                if order_open.nil?
                    flash[:success] = "Não disponível. "
                    return
                end
                order.price = order_open.price
                label_message = "vender"
                label_currency = params[:coin2]
            end
            if BigDecimal(order_open.amount,8) < BigDecimal(order.amount,8)
                order.amount = order_open.amount
                label_bool = false
                flash[:success] = "Você tentou #{label_message} mais #{label_currency} do que a ordem no preço indicado tinha disponível. Sua operação foi reajustada para a quantidade total disponível de #{order.amount} #{label_currency}. Caso queira realizar mais operações instantâneas neste par, utilize o formulário novamente. "
            end
            order.status = "open"
        else
            order = parseOrder(params)
        end
        saldos = eval(get_saldo(current_user))
        order.has_execution = false
        total_value = BigDecimal(order.amount,8) * BigDecimal(order.price,8)
        case params[:type]
        when "buy"
            compare_value = total_value
            saldo = saldos[params[:coin2]]
            discount_currency = params[:coin2]
            operation = "exchange_buy"
            consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt AND price <= :preco", {str_par: order.par, tupe: "sell", stt: "open", preco: order.price}).order(price: :asc)
        when "sell"
            compare_value = order.amount
            saldo = saldos[params[:coin1]]
            discount_currency = params[:coin1]
            operation = "exchange_sell"
            consulta_ordem_oposta = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt AND price >= :preco", {str_par: order.par, tupe: "buy", stt: "open", preco: order.price}).order(price: :desc)
        end
        if BigDecimal(saldo,8) >= BigDecimal(compare_value,8)
            
            id = add_saldo(current_user,discount_currency,compare_value.to_s,operation)
            Payment.exchange_payment(current_user,id,discount_currency,compare_value.to_s,"open_order_#{order.tipo}",order.par)
            
            check_active_orders(order,consulta_ordem_oposta,params[:type])
            if label_bool
                flash[:success] = "Ordem adicionada ao livro! "
            end
        else
            flash[:success] = "Não há saldo para iniciar esta negociação "
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
            ActionCable.server.broadcast 'last_orders',
                status: order.status,
                last_price: order.price,
                pair: order.par.tr("/","_"),
                orders: args[0][:order_list],
                tipo: order.tipo
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
        inicial_amount = BigDecimal(order.amount,8)
        current_amount = inicial_amount
        if consulta_ordem_oposta.empty?
            if order.save
                list = table_orders(order.par,order.tipo)[:table]
                if list.include?(order)
                    broadcast_order(order,{order_list: list})
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
                    end    
                end
                case order.tipo
                when "buy"
                    #adicionar saldo order.amount ao dono da order (compra)
                    saldo1 = (BigDecimal(saldo_buy,8)*0.995).to_s
                    #p "adicionar saldo de #{saldo1} #{params[:coin1]} para #{User.find(order.user_id).first_name}"
                    saldo1_id = add_saldo(User.find(order.user_id),params[:coin1],saldo1,"exchange_credit")
                    Payment.exchange_payment(User.find(order.user_id),saldo1_id,params[:coin1],saldo1,"#{order.tipo}_order_execution",order.par)
                    #adicionar saldo b.amount * b.price ao dono da b (compra)
                    saldo2 = (BigDecimal(((saldo_buy * BigDecimal(b.price,8))*0.995),8)).to_s
                    #p "adicionar saldo de #{saldo2} #{params[:coin2]} para #{User.find(b.user_id).first_name}"
                    saldo2_id = add_saldo(User.find(b.user_id),params[:coin2],saldo2,"exchange_credit")
                    Payment.exchange_payment(User.find(b.user_id),saldo2_id,params[:coin2],saldo2,"#{b.tipo}_order_execution",b.par)
                    string_type = "sell"
                when "sell"
                    
                    coin2_sell_price = ((BigDecimal(saldo_sell,8) * BigDecimal(b.price,8)) * 0.995).to_s
                    #p "adicionar saldo de #{BigDecimal(coin2_sell_price,8)} #{params[:coin2]} para #{User.find(order.user_id).first_name}"
                    coin2_sell_id = add_saldo(User.find(order.user_id),params[:coin2],BigDecimal(coin2_sell_price,8),"exchange_credit")
                    Payment.exchange_payment(User.find(order.user_id),coin2_sell_id,params[:coin2],BigDecimal(coin2_sell_price,8).to_s,"#{order.tipo}_order_execution",order.par)
                    
                    coin1_sell_price = (BigDecimal((saldo_sell * 0.995),8)).to_s
                    #p "adicionar saldo de #{coin1_sell_price} #{params[:coin1]} para #{User.find(b.user_id).first_name}"
                    coin1_sell_id = add_saldo(User.find(b.user_id),params[:coin1],coin1_sell_price,"exchange_credit")
                    Payment.exchange_payment(User.find(b.user_id),coin1_sell_id,params[:coin1],coin1_sell_price,"#{b.tipo}_order_execution",b.par)
                    string_type = "buy"
                end
                list = table_orders(order.par,string_type)[:table]
                broadcast_order(order_to_broadcast,{order_list: list})
            end
        end
        #head :ok
    end
    def order_type(arg)
        if arg == "buy"
            'sell'
        else
            'buy'
        end
    end
    
    def parseOrder(params)
        new_order = current_user.exchangeorder.new
        new_order.par = "#{params[:coin1]}/#{params[:coin2]}"
        new_order.tipo = params[:type]
        new_order.amount = params[:amount]
        new_order.price = params[:price]
        new_order.status = "open"
        new_order
    end
end
