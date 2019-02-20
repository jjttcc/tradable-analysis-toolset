class AddColumnsToTradableSymbols < ActiveRecord::Migration[5.0]
  def change
    add_column :tradable_symbols, :tracking_count, :integer, null: false,
      default: 0
    add_index  :tradable_symbols, :tracking_count
  end
end
