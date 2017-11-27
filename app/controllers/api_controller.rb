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
end
