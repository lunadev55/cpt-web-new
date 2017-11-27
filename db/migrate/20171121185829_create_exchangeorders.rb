class CreateExchangeorders < ActiveRecord::Migration
  def change
    create_table :exchangeorders do |t|
      t.string :par
      t.string :tipo
      t.string :amount
      t.boolean :has_execution
      t.string :price
      t.string :status
      t.string :user_id

      t.timestamps null: false
    end
  end
end
