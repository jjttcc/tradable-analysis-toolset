class AddColumnsToExchanges < ActiveRecord::Migration[5.0]
  def change
    add_column :exchanges, :full_name, :string
  end
end
