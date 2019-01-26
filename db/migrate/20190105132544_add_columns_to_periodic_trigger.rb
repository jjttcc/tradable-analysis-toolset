class AddColumnsToPeriodicTrigger < ActiveRecord::Migration[5.0]
  def change
    add_column :periodic_triggers, :status, :integer, default: 1,
      null: false
    add_column :periodic_triggers, :lock_version, :integer, default: 0,
      null: false
  end
end
