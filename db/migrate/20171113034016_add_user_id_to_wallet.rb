class AddUserIdToWallet < ActiveRecord::Migration
  def change
    add_column :wallets, :user_id, :string
  end
end
