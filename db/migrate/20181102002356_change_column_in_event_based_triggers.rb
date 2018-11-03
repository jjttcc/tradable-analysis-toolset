class ChangeColumnInEventBasedTriggers < ActiveRecord::Migration[5.0]
  def up
    change_column_null :event_based_triggers, :active, false
    change_column_default :event_based_triggers, :active, false
  end

  def down
    change_column_null :event_based_triggers, :active, true
    change_column_default :event_based_triggers, :active, nil
  end
end
