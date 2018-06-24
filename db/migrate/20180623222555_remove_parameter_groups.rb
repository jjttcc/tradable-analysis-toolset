class RemoveParameterGroups < ActiveRecord::Migration[5.0]
  def change
    # Remove foreign key from tradable_processor_parameters to parameter_groups:
    remove_reference :tradable_processor_parameters, :parameter_group, foreign_key: true, index: true
    # (Attempt to make it reversible.)
    drop_table :parameter_groups do |t|
      t.varchar "name"
      t.integer "user_id"
      t.timestamps null: false
      t.index :user_id
      t.index :name
    end
  end
end
