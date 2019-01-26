class AddIndexToSymbolLists < ActiveRecord::Migration[5.0]
  def change
    add_index :symbol_lists, :name
  end
end
