class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user_session, :current_user, :get_saldo, :require_user

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
  def require_user
    unless !current_user.nil? 
      flash[:success] = "Esta página requer login!"
      redirect_to '/sign_in'
    end
  end
  
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def cpt_push(route,params)
    url = URI.parse("https://cpttransactions.herokuapp.com/#{route}")
    req = Net::HTTP::Post.new(url.request_uri)
    params['key'] = ENV['TRANSACTION_KEY']
    req.set_form_data(params)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == "https")
    response = http.request(req)
    response
  end
  #operações de saldo
  def cpt_transaction_user(user,id,username,email) #criar usuário
        route = 'add_users'
        params = {'username'=> username, 'email'=> email, 'id_original'=> id, 'name'=> user}
        cpt_push(route,params)
  end
  def add_saldo(usuario,moeda,qtd,tipo) #função para adicionar saldo em depóstios
    route = 'add_saldo'
    params = {'username'=> usuario.username, 'id_original'=> usuario.id, 'currency'=>moeda, 'amount'=>qtd, 'type'=>tipo}
    cpt_push(route,params)
  end
  def get_saldo(usuario)
    route = 'get_saldo'
    params = {'username'=> usuario.username, 'id_original'=> usuario.id}
    cpt_push(route,params).body
  end
  def cpt_transaction_add(currency,type,user_id,debit_credit,amount)
    route 'add_transaction'
    params = {'currency'=> currency, 'type'=> type, 'user_id'=> user_id, 'debit_credit'=> debit_credit, 'amount'=> amount}
    cpt_push(route,params)
  end
end
