class AddTagToWallets < ActiveRecord::Migration
  def change
    add_column :wallets, :dest_tag, :string
  end
end
