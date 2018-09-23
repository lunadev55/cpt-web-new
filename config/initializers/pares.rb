#Arquivo de configuração de pares de moedas negociáveis

EXCHANGE_PARES = ["LTC / BTC", "LTC / BCH", "BCH / BTC", "ETH / BTC","DOGE / BTC", "ETH / LTC", "BCH / ETH", "DASH / BTC", "DASH / LTC", "DGB / BTC", "DGB / DOGE","ZEC / BTC", "ZEC / ETH"]

#Quais moedas a exchange suporta
MOEDAS_SUPORTADAS = ["BTC","LTC","DOGE","ETH","BCH", "DASH","XMR","BRL", "DGB"]
#Moedas ativas
MOEDAS_ATIVAS = ["BTC","LTC","DOGE","ETH", "BCH", "DASH", "DGB", "ZEC"]

#Nomes das moedas
MOEDAS_ATIVAS_NAMES = Hash.new 
array_nomes = ["Bitcoin","Litecoin","Dogecoin","Ethereum","BitcoinCash","Dash","Digibyte","Zcash"]
counter = 0

TAXES = Hash.new

result = Coinpayments.rates({accepted: "1"})

MOEDAS_ATIVAS.each do |symbol|
    MOEDAS_ATIVAS_NAMES[symbol] = array_nomes[counter]
    TAXES[symbol] = result[symbol][:tx_fee]
    counter += 1
end

BANCOS = ["001 Banco do Brasil","002 Banco Central do Brasil", "003 Banco da Amazônia"]
VINCULOS = ["Individual","Conjunta"]