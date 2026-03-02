class CreateCompany < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :city
      t.string :state

      t.timestamps
    end
  end
end
