class AddDataToMasSession < ActiveRecord::Migration
  def change
    add_column :mas_sessions, :data, :text
  end
end
