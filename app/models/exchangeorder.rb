class Exchangeorder < ActiveRecord::Base
    paginates_per 15
    belongs_to :user
end
