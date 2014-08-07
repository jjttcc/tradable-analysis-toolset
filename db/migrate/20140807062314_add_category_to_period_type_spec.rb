class AddCategoryToPeriodTypeSpec < ActiveRecord::Migration
  def change
    add_column :period_type_specs, :category, :string
    add_index :period_type_specs, :category
  end
end
