class CreateActiveRequests < ActiveRecord::Migration[5.0]
  def change
    create_table :active_requests do |t|
      t.string :user_id
      t.string :document_photo 
      t.string :document_selfie
      t.string :status
      
      t.timestamps
    end
  end
end
