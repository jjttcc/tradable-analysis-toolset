class CreateSymbolLists < ActiveRecord::Migration[5.0]
  def change
    create_table :symbol_lists do |t|
      t.string :name, null: false
      t.string :description
      t.integer :symbols, array: true

      t.timestamps
    end
  end
end
