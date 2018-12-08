class TradableAnalyzersAddConstraintNotNullEtc < ActiveRecord::Migration[5.0]
  def change
    change_column :tradable_analyzers, :name, :text, null: false
    change_column :tradable_analyzers, :event_id, :integer, null: false
    change_column :tradable_analyzers, :is_intraday, :boolean, null: false
  end
end
