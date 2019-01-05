class AddColumnsToAnalysisProfileRun < ActiveRecord::Migration[5.0]
  def change
    add_column :analysis_profile_runs, :notification_status, :integer,
      default: 1, null: false
    add_column :analysis_profile_runs, :lock_version, :integer,
      default: 0, null: false
  end
end
