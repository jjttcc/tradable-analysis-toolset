class RenameEbtActiveColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :event_based_triggers, :active, :activated
  end
end
