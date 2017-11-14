Coinpayments.configure do |config|
  config.merchant_id     = ENV["COINPAYMENT_ID"]
  config.public_api_key  = ENV["COINPAYMENT_PUB"]
  config.private_api_key = ENV["COINPAYMENT_PRIV"]
end
