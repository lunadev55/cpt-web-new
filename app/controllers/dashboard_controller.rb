class DashboardController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:deposit_verify]
    before_action :require_user
    require 'net/http'
    require 'net/https'
    def index
        session[:current_place] = "overview"
    end
    def wallets_view
        @wallet = current_user.wallet.where('currency = :moeda', {moeda: params[:currency]})
    end
    def deposit_verify
        deposit = current_user.payment.find(params[:id])
        deposit.label = "deposit_operation_pendent"
        deposit.endereco = params[:deposit_photo]
        if deposit.save
            redirect_to '/dashboard/index'
        end
    end
end
