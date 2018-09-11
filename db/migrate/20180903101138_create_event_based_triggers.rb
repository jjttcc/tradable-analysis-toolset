class CreateEventBasedTriggers < ActiveRecord::Migration[5.0]
  def change
    create_table :event_based_triggers do |t|
      t.integer :triggered_event_type
      t.boolean :active

      t.timestamps
    end
  end
end
