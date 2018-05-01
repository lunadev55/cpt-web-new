#Arquivo de configuração de pares de moedas negociáveis

EXCHANGE_PARES = ["BTC / BCH", "LTC / BTC", "ETH / BTC","DOGE / BTC", "ETH / LTC", "BCH / ETH", "BCH / LTC", "DASH / BTC", "DASH / LTC"]

#Quais moedas a exchange suporta
MOEDAS_SUPORTADAS = ["BTC","LTC","DOGE","ETH","BCH", "DASH","XMR","BRL"]
#Moedas ativas
MOEDAS_ATIVAS = ["BTC","LTC","DOGE","ETH", "BCH", "DASH"]

#Nomes das moedas
MOEDAS_ATIVAS_NAMES = Hash.new 
array_nomes = ["Bitcoin","Litecoin","Dogecoin","Ethereum","BitcoinCash","Dash","Real"]
counter = 0
MOEDAS_ATIVAS.each do |names|
    MOEDAS_ATIVAS_NAMES[names] = array_nomes[counter]
    counter += 1
end

BANCOS = ["001 Banco do Brasil","002 Banco Central do Brasil", "003 Banco da Amazônia"]
VINCULOS = ["Individual","Conjunta"]