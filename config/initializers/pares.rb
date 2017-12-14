#Arquivo de configuração de pares de moedas negociáveis

EXCHANGE_PARES = ["LTC / BTC","ETH / BTC","DOGE / BTC", "ETH / LTC", "XMR / BTC", "BCH / BTC", "DASH / BTC"]

#Quais moedas a exchange suporta
MOEDAS_SUPORTADAS = ["BTC","LTC","DOGE","ETH","BCH", "DASH","XMR"]
#Moedas ativas
MOEDAS_ATIVAS = ["BTC","LTC","DOGE","ETH", "BCH", "DASH","XMR"]

#Nomes das moedas
MOEDAS_ATIVAS_NAMES = Hash.new 
array_nomes = ["Bitcoin","Litecoin","Dogecoin","Ethereum","BitcoinCash","Dash","Monero"]
counter = 0
MOEDAS_ATIVAS.each do |names|
    MOEDAS_ATIVAS_NAMES[names] = array_nomes[counter]
    counter += 1
end