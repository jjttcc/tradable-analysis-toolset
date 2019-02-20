class AddExchangesRefToTradableSymbols < ActiveRecord::Migration[5.0]
  def change
    add_reference :tradable_symbols, :exchange, foreign_key: true
  end
end
