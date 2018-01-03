class UsersController < ApplicationController
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
  

  private

  def users_params
    params.require(:user).permit(:email, :password, :password_confirmation, :username, :birth, :document, :phone, :first_name, :last_name)
  end
end