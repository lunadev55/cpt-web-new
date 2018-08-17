class User < ApplicationRecord
  has_many :wallet
  has_many :exchangeorder
  has_many :payment
  has_many :active_request
  has_many :apiInfo
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :username, presence: true
  
  def as_json
    {
      "id": 2,
      "email": self.email,
      "qtd_logins": self.login_count,
      "failed_login_count": 0,
      "last_login_at": "2018-07-12T21:58:42.187Z",
      "current_login_ip": "45.224.25.32",
      "last_login_ip": "177.38.34.53",
      "username": self.username,
      "document": self.document,
      "full_name": "#{self.first_name} #{self.last_name}",
    }
  end
  
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.login_field = :email
  end
  
  def full_name
    return "#{self.first_name} #{self.last_name}"
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    PasswordResetMailer.reset_email(self).deliver_now
  end
  
  
end
