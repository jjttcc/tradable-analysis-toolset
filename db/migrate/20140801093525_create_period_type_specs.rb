class CreatePeriodTypeSpecs < ActiveRecord::Migration
  def change
    create_table :period_type_specs do |t|
      t.integer :period_type_id
      t.datetime :start_date
      t.datetime :end_date
      t.references :user

      t.timestamps
    end
    add_index :period_type_specs, :user_id
  end
end
