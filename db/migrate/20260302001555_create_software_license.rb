class CreateSoftwareLicense < ActiveRecord::Migration[8.0]
  def change
    create_table :software_licenses do |t|
      t.string :software_name, null: false
      t.string :license_key, null: false
      t.date :expiration_date, null: false
      t.references :asset, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
