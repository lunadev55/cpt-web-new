class ChangeStringToBeFloatInExchangeorders < ActiveRecord::Migration[5.0]
  def change
    change_column :exchangeorders, :price, :float
    change_column :exchangeorders, :amount, :float
  end
end
