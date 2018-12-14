class CreateTradableEventSets < ActiveRecord::Migration[5.0]
  def change
    create_table :tradable_event_sets do |t|
      t.references :tradable_processor_run, foreign_key: true, null: false
      t.string :symbol, null: false

      t.timestamps
    end
  end
end
