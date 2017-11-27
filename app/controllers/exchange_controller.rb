class ExchangeController < ApplicationController
    def render_orders
        session[:currency1] = params[:coin1]
        session[:currency2] = params[:coin2]
    end
    
    def cancel_order
        @order = current_user.exchangeorder.find(params[:id])
        par = @order.par.split('/')
        if @order.status != "open"
            return
        end
        case @order.tipo
        when "buy"
            @order.status = "cancelled"
            @order.save
            flash[:success] = "adicionar #{(BigDecimal(@order.amount,8) * BigDecimal(@order.price,8))} #{par[1]}" 
            add_saldo(current_user,par[1],(BigDecimal(@order.amount,8) * BigDecimal(@order.price,8)),"cancel_buy")
        when "sell"
            @order.status = "cancelled"
            @order.save
            flash[:success] = "adicionar #{@order.amount} #{par[0]}"
            add_saldo(current_user,par[0],@order.amount,"cancel_sell")
        end
    end
    
    def create_order
        saldos = eval(get_saldo(current_user))
        order = parseOrder(params)
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
        if saldo > BigDecimal(compare_value,8)
            
            add_saldo(current_user,discount_currency,compare_value.to_s,operation)
            check_active_orders(order,consulta_ordem_oposta,params[:type])
            flash[:success] = "Ordem adicionada ao livro! "
        else
            flash[:success] = "Não há saldo para iniciar esta negociação "
        end
        @order = order
    end
    
    private
    def check_active_orders(order,consulta_ordem_oposta,buysell)
        inicial_amount = BigDecimal(order.amount,8)
        current_amount = inicial_amount
        if consulta_ordem_oposta.empty?
            order.save
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
                        b.amount = result_amount.to_s #resultante do montante das duas transações é o que sobra na transação do livro convertido em string
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
                        new.save
                        current_amount = 0
                        order.status = "executada"
                        order.has_execution = true
                        order.save
                        
                    when b_amount <= o_amount
                        result_amount = o_amount - b_amount
                        if result_amount < 0
                            order.has_execution = true
                            order.status = "executada"
                        else
                            order.amount = result_amount
                        end
                        b.status = "executada"
                        b.save
                        
                        order.save
                        
                        
                    end    
                end
                case order.tipo
                when "buy"
                    #adicionar saldo order.amount ao dono da order (compra)
                    #adicionar saldo de order.amount pro dono de order (compra)
                    add_saldo(User.find(order.user_id),params[:coin1],(BigDecimal((order.amount * 0.995),8).to_s),"exchange_credit")
                    #adicionar saldo b.amount * b.price ao dono da b (compra)
                    #adicionar saldo de order.amount * price para dono da ordem b (compra)
                    add_saldo(User.find(b.user_id),params[:coin2],BigDecimal((BigDecimal(order.amount,8) * BigDecimal(b.price,8))*0.995),8)
                when "sell"
                    #adicionar saldo de order.amount * price para dono da order (venda)
                    add_saldo(User.find(order.user_id),params[:coin2],BigDecimal((BigDecimal(order.amount,8) * BigDecimal(b.price,8))*0.995),8)
                    #adicionar asldo de order.amount pro dono de b (venda)
                    add_saldo(User.find(b.user_id),params[:coin1],(BigDecimal((order.amount * 0.995),8).to_s))
                end
            end
        end
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
    def conclude_orders(order1,order2)
    end
end
