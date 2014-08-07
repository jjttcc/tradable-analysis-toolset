class RemoveIndexFromPeriodTypeSpecs < ActiveRecord::Migration
  def up
    remove_index :period_type_specs, :category
  end

  def down
    add_index :period_type_specs, :category
  end
end
