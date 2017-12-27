class Exchangeorder < ApplicationRecord
    paginates_per 15
    belongs_to :user
    def self.save
        broadcast_order(self)
    end
end
