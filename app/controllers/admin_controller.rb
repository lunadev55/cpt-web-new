class AdminController < ApplicationController
    before_action :require_admin
    def confirm_saldo
        user = User.find_by_email(params[:user_email])
        moeda = params[:currency_base]
        amount = params[:amount]
        tipo = params[:tipo]
        if !(user.nil?)
           p add_saldo(user,moeda,amount,tipo)
        end
    end
    def register_users
        a = User.all
        a.each do |m|
            cpt_transaction_user(a)
        end
    end
end
