class DropPeriodTypes < ActiveRecord::Migration
  def up
    # ('period_types' table is not needed.)
    drop_table :period_types
  end

  def down
  end
end
