class AnalysisScheduleAddConstraintsNotNullEtc < ActiveRecord::Migration[5.0]
  def change
    change_column :analysis_schedules, :name, :string, null: false
    change_column :analysis_schedules, :active, :boolean, null: false
    change_column :analysis_schedules, :user_id, :integer, null: false
    add_index :analysis_schedules, [:name, :user_id], unique: true
  end
end
