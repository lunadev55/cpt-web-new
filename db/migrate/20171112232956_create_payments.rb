class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string :user_id
      t.string :status
      t.string :label
      t.string :endereco
      t.string :volume
      t.string :network
      t.string :txid

      t.timestamps null: false
    end
  end
end
