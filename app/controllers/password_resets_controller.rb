class PasswordResetsController < ApplicationController
  before_action :require_user, :only => [:change_pass]
  def new
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.deliver_password_reset_instructions!
      flash[:info] = "Instruções de reset foram enviadas para o seu email."
      redirect_to root_path
    else
      flash[:info] = "Email não encontrado!"
      render :new
    end
  end

  def edit
    @user = User.find_by(perishable_token: params[:id])
  end
  
  def change_pass
    @user = current_user
    @session = UserSession.new(password_reset_params)
    if password_reset_params['new_password'] != password_reset_params['password_confirmation']
      flash[:info] = "Senhas não coincidem! "
      return
    end
    if @session.save
      @user = current_user
      @user.password = password_reset_params['new_password']
      @user.password_confirmation = password_reset_params['password_confirmation']
      if @user.changed? && @user.save
        UserSession.create(:email => @user.email, :password => password_reset_params['new_password'])
        flash[:info] = "Senha atualizada com sucesso! "
      end
    else
      flash[:info] = "Senha incorreta, tente novamente. "
    end
  end
  
  def update
    @user = User.find_by(perishable_token: params[:id])
    if @user.update_attributes(password_reset_params)
      flash[:info] = "Senha atualizada com sucesso! "
      redirect_to root_path
    else
      render :edit
    end
  end
  

  private

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation, :new_password, :email)
  end
end