class ModifyAnalysisRun < ActiveRecord::Migration[5.0]
  def change
    remove_column    :analysis_runs, :analysis_profile_name
    remove_column    :analysis_runs, :analysis_profile_client
    remove_column    :analysis_runs, :run_start_time
    remove_reference :analysis_runs, :user, foreign_key: true, null: false
    add_reference    :analysis_runs, :analysis_profile_run, foreign_key: true
    change_column    :analysis_runs, :analysis_profile_run_id, :integer,
      null: false
  end
end
