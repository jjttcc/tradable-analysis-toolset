class CreatePeriodTypeSpecsV2 < ActiveRecord::Migration
  def up
    create_table :period_type_specs do |t|
      t.integer  :period_type_id,  :null => false
      t.datetime :start_date
      t.datetime :end_date
      t.integer  :user_id

      t.timestamps
    end
    add_index :period_type_specs, :user_id
  end

  def down
    remove_index :period_type_specs, :user_id
    drop_table :period_type_specs
  end
end
