class RenamePeriodicTriggerDailySchedToSchedType < ActiveRecord::Migration[5.0]
  def change
    rename_column :periodic_triggers, :daily_schedule, :schedule_type
  end
end
