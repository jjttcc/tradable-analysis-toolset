class AnalysisRunAddConstraints < ActiveRecord::Migration[5.0]
  def change
    change_column :analysis_runs, :status, :integer, null: false
    change_column :analysis_runs, :start_date, :datetime, null: false
    change_column :analysis_runs, :end_date, :datetime, null: false
    change_column :analysis_runs, :analysis_profile_name, :string, null: false
    change_column :analysis_runs, :analysis_profile_client, :string, null: false
    change_column :analysis_runs, :user_id, :integer, null: false
    change_column :analysis_runs, :run_start_time, :datetime, null: false
  end
end
