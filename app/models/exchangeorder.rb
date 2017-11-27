class Exchangeorder < ActiveRecord::Base
    paginates_per 20
    belongs_to :user
end
