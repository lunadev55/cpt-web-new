class User < ActiveRecord::Base
  has_many :wallet
  has_many :exchangeorder
  has_many :payment
  validates :email, presence: true
  validates :username, presence: true
  
  
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::Sha512
    c.login_field = :email
  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    PasswordResetMailer.reset_email(self).deliver_now
  end
  
  
end
