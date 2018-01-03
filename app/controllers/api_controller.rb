class ApiController < ApplicationController
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
        elsif params[:tipo] == "sell"
            a = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: "#{params[:coin1]}/#{params[:coin2]}", tupe: "buy", stt: "open"}).order(price: :desc).limit(1)
        end
         
        if a.empty?
            render plain: "Não disponível."
        else
            p a[0].price
            render plain: "#{a[0].price} #{params[:coin2]}"
        end
    end
end
