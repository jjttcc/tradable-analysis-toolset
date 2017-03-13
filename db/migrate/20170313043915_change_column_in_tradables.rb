class ChangeColumnInTradables < ActiveRecord::Migration[5.0]
  def change
    change_column :tradables, :symbol, :string, null: false
    change_column :tradables, :name, :text, null: false
  end
end
