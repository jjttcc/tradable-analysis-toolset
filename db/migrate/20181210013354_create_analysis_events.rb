class CreateAnalysisEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :analysis_events do |t|
      t.references :tradable_event_set, foreign_key: true, null: false
      t.integer :event_type_id, null: false
      t.datetime :date_time, null: false
      t.string :signal_type, null: false

      t.timestamps
    end
  end
end
