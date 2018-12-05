class AddSaveResultsToAnalysisProfile < ActiveRecord::Migration[5.0]
  def change
    add_column :analysis_profiles, :save_results, :boolean
  end
end
