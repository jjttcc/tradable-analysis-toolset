class CreateAnalysisProfileRuns < ActiveRecord::Migration[5.0]
  def change
    create_table :analysis_profile_runs do |t|
      t.references :user, foreign_key: true, null: false
      t.references :analysis_profile, foreign_key: true
      t.string :analysis_profile_name, null: false
      t.string :analysis_profile_client, null: false
      t.datetime :run_start_time, null: false
      t.datetime :expiration_date, null: false

      t.timestamps
    end
  end
end
