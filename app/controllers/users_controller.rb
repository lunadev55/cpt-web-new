class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:active_request_new]
  before_action :new, :only => [:bank_operation, :new_bank_account]
  def new
    if current_user.nil?
      @user = User.new
    else
      @user = current_user
    end
  end
  def bank_operation
    @account = Wallet.find(params[:id])
    case params[:op]
    when "edit"
      @wallet = @account
      @hash = eval(decrypt_data(@wallet.address))
    when "delete"
      @account.delete
      flash[:success] = "Conta deletada do sistema! "
    end
  end
  def new_bank_account
    if request.get?
      @walltet = Wallet.new
      #formulário para conta nova  
    elsif request.post?
      if params[:id] == nil
        account = current_user.wallet.new
        account.currency = "BRL"
        flash[:success] = "Conta cadastrada! "
      else
        account = current_user.wallet.find(params[:id])
        flash[:success] = "Alterações salvas! "
      end
      account.dest_tag = params[:banco]
      account_data = Hash.new
      account_data[:conta] = params[:conta]
      account_data[:agencia] = params[:agencia]
      account_data[:joint_account] = params[:joint_account]
      account_data[:tipo_conta] = params[:tipo_conta]
      account_data[:account_holder] = params[:account_holder]
      data = String(encrypt_data(account_data.to_s))
      account.address = data
      account.save
    end
  end
  def create
    @user = User.new(users_params)
    isNew = true
    if users_params['id'] != nil 
      @user.id = users_params['id']
      isNew = false
    end
    @user.role = "inactive"
    if @user.save
      if isNew != false
        flash[:success] = "Cadastrado com Sucesso!"
        cpt_transaction_user(@user)
        redirect_to '/dashboard/index'
      else
        flash[:success] = "Sucesso!"
        redirect_to '/dashboard/index'
      end
    else
      render :new
    end
  end
  def edit
    @user = current_user
  end
  
  def active_request_new
    request = current_user.active_request.new
    request.document_photo = params[:photo]
    request.document_selfie = params[:selfie]
    request.status = 'pendente'
    request.save
    admin = User.find_by_email('admin@cptcambio.com')
    text = "Um novo pedido de validação de cadastro foi efetuado."
    deliver_generic_email(admin,text,"Novo pedido de validação de cadatro.")
    deliver_generic_email(current_user,"Seu pedido de validação foi recebido! <br> Aguarde informações futuras em seu email para verificar a resposta de nossa equipe de suporte.","Solicitação #{request.id}")
    session[:redirect] = "editInfo"
    @user = current_user
    redirect_to '/dashboard/index'
  end

  private

  def users_params
    params.require(:user).permit(:email, :password, :password_confirmation, :username, :birth, :document, :phone, :first_name, :last_name)
  end
end