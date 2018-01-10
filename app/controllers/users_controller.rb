class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:active_request_new]
  def new
    if current_user.nil?
      @user = User.new
    else
      @user = current_user
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