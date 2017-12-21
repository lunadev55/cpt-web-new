class Payment < ApplicationRecord
    paginates_per 20
    belongs_to :user
end
