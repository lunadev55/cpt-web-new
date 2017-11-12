class AddDocumentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :birth, :string
    add_column :users, :document, :string
    add_column :users, :phone, :string
  end
end
