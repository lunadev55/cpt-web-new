class TraderController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:graph,:postRequests]
    
    def postRequests
        case params[:option]
        when 'newOrder'
            newOrder
        end
    end
    def newOrder
        exchange = ExchangeController.new
        result = exchange.create_order(
            pair: params[:pair],
            amount: params[:amount], 
            price: params[:price], 
            type: params[:type], 
            user: current_user.id
        )
        
        render 'newOrder'
    end
    
    def proxyRequest
        case params[:option]
        when 'negociar'
            @view = "/trader/order_forms"
            @html_element = "render_trader_helper"
        when 'ordens_abertas'
            @view = "/exchange/open_orders"
            @html_element = "render_trader_helper"
        end
    end
    def graph
        date_inicio = (Time.parse(params[:date_inicio]) - 1.days )
        date_fim = (Time.parse(params[:date_fim]) + 1.days)
        pair = params[:pair].tr("_","/")
        query = Exchangeorder.where("par = '#{pair}' AND created_at >= '#{date_inicio.utc}' AND created_at <= '#{date_fim.utc}' AND status = 'executada'").order(:created_at)
        render plain: query.to_json
    end
    def graph_old
        pair = params[:pair].tr("_","/")
        result = Array.new
        query = Exchangeorder.where("par = '#{pair}'").order(:created_at)
        minutes1 = Date.today - 1.months
        hora_final = query.last.created_at
        
        while minutes1 < hora_final
            minutes2 = minutes1 + 10.minutes
            p candles = query.where("'#{minutes1}' <= created_at AND created_at <= '#{minutes2}'")
            minutes1 += 10.minutes #Itera de 5 em 5 minutos
            high = 0
            low = 0
            volume = 0
            candles.each do |candle|
                if candle.price >= high
                    high = candle.price
                end
                if candle.price <= low
                    low = candle.price
                elsif low == 0
                    low = candle.price
                end
                volume += candle.amount
            end
            if candles.size > 0
                p temp = {
                    "open": candles.first.price,
                    "close": candles.last.price,
                    "high": high,
                    "low": low,
                    "volume": volume,
                    "date": candles.first.created_at
                }
                
                result << temp
            end
        end
        
        render text: result.to_json
    end
end
