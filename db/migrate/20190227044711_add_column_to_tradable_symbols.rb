class AddColumnToTradableSymbols < ActiveRecord::Migration[5.0]
  def change
    add_column :tradable_symbols, :tracked, :boolean, null: false, default:
      false
    add_index  :tradable_symbols, :tracked
  end
end
