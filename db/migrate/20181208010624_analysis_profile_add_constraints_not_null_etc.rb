class AnalysisProfileAddConstraintsNotNullEtc < ActiveRecord::Migration[5.0]
  def change
    change_column :analysis_profiles, :name, :string, null: false
    change_column :analysis_profiles, :analysis_client_type, :string,
      null: false
    change_column :analysis_profiles, :analysis_client_id, :integer,
      null: false
    add_index :analysis_profiles, [:name, :analysis_client_id], unique: true
  end
end
