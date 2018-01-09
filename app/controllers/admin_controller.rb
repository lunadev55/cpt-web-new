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
    def request_details
        @request = ActiveRequest.find(params[:request_id])
        @user = User.find(@request.user_id)
    end
    def active_account
        @request = ActiveRequest.find(params[:request_id])
        @user = User.find(@request.user_id)
        case params[:commit].downcase
        when "ativar"
            @user.role = "active"
            @user.first_name = params[:first_name]
            @user.last_name = params[:last_name]
            @user.username = params[:username]
            @user.birth = params[:birth]
            @user.document = params[:document]
            message = "Olá #{params[:first_name]} #{params[:last_name]}. <br> Estamos felizes em dizer que sua solicitação de ativação de cadastro foi verificada! Você agora está apto a realizar negócios com a Cripto câmbio Exchange.<br> Acesse nosso site e faça um Tour pela nossa interface: <a href='http://www.cptcambio.com/sign_in'>Cptcambio</a>"
        when "desativar"
            @user.role = "inactive"
            message = "Olá #{params[:first_name]} #{params[:last_name]}. <br> Infelizmente sua solicitação não foi verificada pelo motivo de: #{params[:justify]}.<br> Para ativar sua conta, pedimos que refaça o envio dos documentos atendendo aos requisitos necessários."
        end
        if @request.delete
            deliver_generic_email(@user,message,"Solicitação #{@request.id} - Cripto Câmbio")
        end
    end
end
