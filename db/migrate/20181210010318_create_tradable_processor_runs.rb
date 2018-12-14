class CreateTradableProcessorRuns < ActiveRecord::Migration[5.0]
  def change
    create_table :tradable_processor_runs do |t|
      t.references :analysis_run, foreign_key: true, null: false
      t.integer :processor_id, null: false
      t.integer :period_type, null: false

      t.timestamps
    end
  end
end
