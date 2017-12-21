class Exchangeorder < ApplicationRecord
    paginates_per 15
    belongs_to :user
end
