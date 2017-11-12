class PasswordResetsController < ApplicationController
  def new
  end

  def create
    @user = User.find_by_email(params[:email])
    if @user
      @user.deliver_password_reset_instructions!
      flash[:success] = "Instruções de reset foram enviadas para o seu email."
      redirect_to root_path
    else
      flash[:warning] = "Email não encontrado!"
      render :new
    end
  end

  def edit
    @user = User.find_by(perishable_token: params[:id])
  end

  def update
    @user = User.find_by(perishable_token: params[:id])
    if @user.update_attributes(password_reset_params)
      flash[:success] = "Password successfully updated!"
      redirect_to root_path
    else
      render :edit
    end
  end

  private

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end