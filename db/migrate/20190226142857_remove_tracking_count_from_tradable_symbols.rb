class RemoveTrackingCountFromTradableSymbols < ActiveRecord::Migration[5.0]
  def change
    remove_column :tradable_symbols, :tracking_count, :integer
  end
end
