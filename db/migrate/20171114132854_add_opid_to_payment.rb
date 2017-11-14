class AddOpidToPayment < ActiveRecord::Migration
  def change
    add_column :payments, :op_id, :string
  end
end
