class CreateWallets < ActiveRecord::Migration
  def change
    create_table :wallets do |t|
      t.string :address
      t.string :currency

      t.timestamps null: false
    end
  end
end
