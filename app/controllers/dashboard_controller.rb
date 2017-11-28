class DashboardController < ApplicationController
    before_action :require_user
    require 'net/http'
    require 'net/https'
    def index
        
    end
    def wallets_view
        @wallet = current_user.wallet.where('currency = :moeda', {moeda: params[:currency]})
    end
end
