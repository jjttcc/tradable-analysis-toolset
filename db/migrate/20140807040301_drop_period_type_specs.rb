class DropPeriodTypeSpecs < ActiveRecord::Migration
  def up
    # Undo the SQL statement to create the period_type_specs table and
    # associated index so that the table can be created in the normal way
    # (in a later migration).
    remove_index :period_type_specs, :user_id
    drop_table :period_type_specs
  end

  def down
  end
end
