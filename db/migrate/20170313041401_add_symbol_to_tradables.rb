class AddSymbolToTradables < ActiveRecord::Migration[5.0]
  def change
    add_column :tradables, :symbol, :string
  end
end
