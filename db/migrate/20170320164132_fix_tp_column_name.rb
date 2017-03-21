class FixTpColumnName < ActiveRecord::Migration[5.0]
  def change
    rename_column :tradable_processors, :type, :tp_type
  end
end
