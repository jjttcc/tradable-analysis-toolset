class CreateExchanges < ActiveRecord::Migration[5.0]
  def change
    create_table :exchanges do |t|
      t.string :name, null: false
      t.integer :type, null: false, default: 1
      t.string :timezone, null: false

      t.index :name, unique: true
      t.timestamps
    end
  end
end
