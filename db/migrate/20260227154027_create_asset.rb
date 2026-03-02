class CreateAsset < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.string :name, null: false
      t.string :asset_type, null: false
      t.string :serial_number
      t.date :purchase_date
      t.references :company, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
