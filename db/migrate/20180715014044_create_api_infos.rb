class CreateApiInfos < ActiveRecord::Migration[5.0]
  def change
    create_table :api_infos do |t|
      t.string :user_id
      t.string :key
      t.string :secret

      t.timestamps
    end
  end
end
