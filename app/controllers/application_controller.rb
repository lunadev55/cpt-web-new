class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user_session, :current_user, :get_saldo, :require_user, :deliver_deposit_email, :blocker_link, :optax, :last_price, :deliver_generic_email, :check_cur_nil, :broadcast_order, :recent_orders, :exchange_label
  require 'sendgrid-ruby'
  include SendGrid 
  private
  def exchange_label(text)
    case text.downcase
    when 'deposit'
      return "Depósito"
    when 'open_order_sell'
      return "Abertura de ordem"
    when 'open_order_buy'
      return "Abertura de ordem"
    when 'buy_order_execution'
      return "Execução de ordem"
    when 'sell_order_execution'
      return "Execução de ordem"
    when 'open_order'
      return "Ordem aberta"
    when 'cancel_buy'
      return "Cancelamento de ordem"
    when 'exchange_open_order_buy'
      return "Ordem de compra"
    when 'exchange_open_order_sell'
      return "Ordem de venda"
    when 'exchange_cancel_buy'
      return "Ordem de compra"
    when 'exchange_cancel_sell'
      return "Cancelamento de ordem"
    when 'cancel_sell'
      return "Cancelamento de ordem"
    when 'exchange_buy_order_execution'
      return "Ordem de compra"
    when 'exchange_sell_order_execution'
      return "Ordem de Venda"
    else
      return text
    end
      
  end
  def recent_orders(pair)
    sell_orders = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: pair, tupe: "sell", stt: "open"}).limit(15).order(price: :asc)
    buy_orders = Exchangeorder.where("par = :str_par AND tipo = :tupe AND status = :stt", {str_par: pair, tupe: "buy", stt: "open"}).limit(15).order(price: :desc)
  end
  
  def require_admin
    require_user
    current_user.role.to_s
    unless current_user.role.to_s == "admin" 
      flash[:success] = "Esta página requer permissões administrativas!"
      redirect_to '/'
    end
  end
  def check_cur_nil
    if session[:currency1].nil?
      base_par = EXCHANGE_PARES.first.tr(" ","").split("/")
      session[:currency1] = base_par[0]
      session[:currency2] = base_par[1]
    end
  end
  def broadcast_order(order)
        ActionCable.server.broadcast 'last_orders',
            status: order.status
  end
  def last_price(pares,tipo,execucao)
    a = Exchangeorder.where("par = :par and tipo = :role and status = :stt", { stt: execucao, par: pares, role: tipo }).last
    if !a.nil?
      a.price
    else
      "NaN"
    end
  end
  
  def blocker_link(network)
    ENV["LINK#{network}"]
  end
  
  def optax(currency)
        case currency
        when "BTC"
            return 0.0007
        when "ETH"
            return 0.0012
        when "LTC"
            return 0.001
        when "DOGE"
            return 1
        when "BRL"
            return 0
        end
  end
  
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
    url = URI.parse("#{ENV["TRANSACTION_URL"]}#{route}")
    req = Net::HTTP::Post.new(url.request_uri)
    params['key'] = ENV['TRANSACTION_KEY']
    
    cipher = OpenSSL::Cipher.new('AES-128-CBC')
    cipher.encrypt
    cipher.key = ENV["CIPHER_RANDOM"]
    cipher.iv = ENV["CIPHER_IV"]
    message = cipher.update(params.to_s) + cipher.final
    
    params = Hash.new
    params[:message] = message
    req.set_form_data(params)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == "https")
    response = http.request(req)
    response.body
  end
  #operações de saldo
  def cpt_transaction_user(user) #criar usuário
    route = 'add_users'
    params = {'username'=> user.username, 'email'=> user.email, 'id_original'=> user.id, 'name'=> "#{user.first_name} #{user.last_name}"}
    cpt_push(route,params)
  end
  def cpt_update_user(user)
    route = 'update_users'
    params = {'username'=> user.username, 'email'=> user.email, 'id_original'=> user.id, 'name'=> "#{user.first_name} #{user.last_name}"}
    cpt_push(route,params)
  end
  def add_saldo(usuario,moeda,qtd,tipo) #função para adicionar saldo em depóstios
    route = 'add_saldo'
    params = {'username' => usuario.username, 'id_original' => usuario.id, 'currency' => moeda, 'amount' => qtd, 'type' => tipo}
    cpt_push(route,params)
  end
  def get_saldo(usuario)
    route = 'get_saldo'
    params = {'id_original'=> usuario.id}
    a = cpt_push(route,params)
    a
  end
  def cpt_transaction_add(currency,type,user_id,debit_credit,amount)
    route 'add_transaction'
    params = {'currency'=> currency, 'type'=> type, 'user_id'=> user_id, 'debit_credit'=> debit_credit, 'amount'=> amount}
    cpt_push(route,params)
  end
  def deliver_generic_email(user,text,title)
    string_body = text
    from = Email.new(email: 'no-reply@cptcambio.com')
    subject = "#{title} - CPT Cambio"
    to = Email.new(email: user.email)
    content = Content.new(type: 'text/html', value: string_body)
    mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._("send").post(request_body: mail.to_json)
    puts response.status_code
  end
  
  def deliver_deposit_email(user,currency,amount,discounted)
    string_body = ""
    string_body << "Olá "
    string_body << "#{user.first_name.capitalize} #{user.last_name.capitalize} "
    string_body << "<br>"
    string_body << "Obrigado por utilizar nossos serviços!<br> Foi realizado um depósito líquido de #{discounted} #{currency} em sua conta.<br>"
    string_body << "\n"
    string_body << "Caso queira verificar detalhes do depósito, acesse nosso sistema.<br>Bons negócios!"
    
    from = Email.new(email: 'no-reply@cptcambio.com')
    subject = 'Depósito - CPT Cambio'
    to = Email.new(email: user.email)
    content = Content.new(type: 'text/html', value: string_body)
    mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._("send").post(request_body: mail.to_json)
    puts 'email enviado aqui'
    puts response.status_code
  end
end
