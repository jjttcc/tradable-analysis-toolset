class CreateTradableSymbols < ActiveRecord::Migration[5.0]
  def change
    create_table :tradable_symbols do |t|
      t.string :symbol, null: false

      t.timestamps
    end

    add_index :tradable_symbols, :symbol, unique: true
    add_foreign_key :tradable_symbols, :tradable_entities,
      column: :symbol, primary_key: :symbol
  end
end
