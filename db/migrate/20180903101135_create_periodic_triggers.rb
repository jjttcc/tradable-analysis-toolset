class CreatePeriodicTriggers < ActiveRecord::Migration[5.0]
  def change
    create_table :periodic_triggers do |t|
      t.integer :interval_seconds
      t.time :time_window_start
      t.time :time_window_end
      t.integer :daily_schedule

      t.timestamps
    end
  end
end
