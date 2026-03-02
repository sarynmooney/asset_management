class CreateNote < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.text :content, null: false
      t.references :asset, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
