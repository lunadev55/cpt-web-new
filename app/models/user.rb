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
      "id": self.id,
      "email": self.email,
      "qtd_logins": self.login_count,
      "failed_login_count": self.failed_login_count,
      "last_login_at": self.last_login_at,
      "last_login_ip": self.last_login_ip,
      "username": self.username,
      "document": self.document,
      "full_name": "#{self.first_name} #{self.last_name}",
      "wallets": (self.wallet.all).as_json
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
