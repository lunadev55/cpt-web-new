class AddHexToPayment < ActiveRecord::Migration
  def change
    add_column :payments, :hex, :string
  end
end
