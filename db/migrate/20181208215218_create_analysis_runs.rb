class CreateAnalysisRuns < ActiveRecord::Migration[5.0]
  def change
    create_table :analysis_runs do |t|
      t.references :user, foreign_key: true
      t.integer :status
      t.datetime :start_date
      t.datetime :end_date
      t.string :analysis_profile_name
      t.string :analysis_profile_client
      t.datetime :run_start_time

      t.timestamps
    end
  end
end
