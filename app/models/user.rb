class User < ApplicationRecord
  has_many :wallet
  has_many :exchangeorder
  has_many :payment
  validates :first_name, presence: true
  validates :last_name, presence: true
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
