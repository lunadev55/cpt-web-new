class Payment < ApplicationRecord
    paginates_per 20
    belongs_to :user
    def self.exchange_payment(user,op_id,currency,amount,operation_type,pair)
        a = user.payment.new
        a.status = operation_type
        a.volume = amount.to_s
        a.network = currency
        a.op_id = op_id
        a.label = "Exchange_#{a.status.capitalize}"
        a.endereco = pair
        a.save
    end
end
