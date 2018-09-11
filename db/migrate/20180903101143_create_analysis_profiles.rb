class CreateAnalysisProfiles < ActiveRecord::Migration[5.0]
  def change
    create_table :analysis_profiles do |t|
      t.string :name
      t.references :analysis_client, polymorphic: true,
        index: {:name => "index_analysis_profiles_on_analysis_client_type_and_id"}

      t.timestamps
    end
  end
end
