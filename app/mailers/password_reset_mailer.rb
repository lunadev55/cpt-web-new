class PasswordResetMailer < ApplicationMailer 
  require 'sendgrid-ruby'
  include SendGrid    
  def reset_email(user)
    route = "https://#{ENV['BASE_URL']}/password_resets/#{user.perishable_token}/edit"
    
    string_body = ""
    string_body << "Olá "
    string_body << user.username.capitalize 
    string_body << "<br>"
    string_body << "Obrigado por utilizar nossos serviços!<br> Este é um email automático para reset de sua senha em nosso sistema.<br>"
    string_body << "\n"
    string_body << "Se não foi você que iniciou este processo ignore esta mensagem. Caso considere que há algo errado entre em contato.<br>Link para reset: <a href='" 
    string_body << route
    string_body << "'>Reset de senha</a>."
    
    p string_body
    
    from = Email.new(email: 'no-reply@cptcambio.com')
    subject = 'Reset senha - CPT Cambio'
    to = Email.new(email: user.email)
    content = Content.new(type: 'text/html', value: string_body)
    mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._("send").post(request_body: mail.to_json)
    puts 'email enviado aqui'
    puts response.status_code
    puts response.headers
  end
end
