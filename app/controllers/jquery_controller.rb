class JqueryController < ApplicationController
    def dashboard_options
        if params[:partial] == "editInfo"
            editInfo
        end
    end
    
    def editInfo
        @user = User.find(params['user_id'])
        if @user == current_user
            if params['email'] != current_user.email
                @user.email = params['email']
            end
            if params['username'] != current_user.username
                @user.username = params['username']
            end
            if params['birth'] != current_user.birth
                @user.birth = params['birth']
            end
            if params['document'] != current_user.document
                @user.document = params['document']
            end
            if params['password'] == params['password_confirmation']
                @user_session = UserSession.new(params)
                if @user_session.save
                    @user.save
                    flash[:success] = "Informações atualizadas!"
                else
                    flash[:success] = "Senha incorreta!"
                end
            else
                flash[:success] = "Senhas Não coincidem!"
            end
            return
        end
    end
end
