class ChangeColumnInAnalysisProfile < ActiveRecord::Migration[5.0]
  def change
    change_column_null :analysis_profiles, :save_results, false
    change_column_default :analysis_profiles, :save_results, false
  end
end
