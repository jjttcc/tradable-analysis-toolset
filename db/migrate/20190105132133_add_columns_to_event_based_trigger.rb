class AddColumnsToEventBasedTrigger < ActiveRecord::Migration[5.0]
  def change
    add_column :event_based_triggers, :status, :integer, default: 1,
      null: false
    add_column :event_based_triggers, :lock_version, :integer, default: 0,
      null: false
  end
end
