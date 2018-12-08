# Please ignore the messed up name (...Analyzers...).
class EventGenerationProfilesAnalyzersAddConstraintNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column :event_generation_profiles, :analysis_period_length_seconds,
      :integer, null: false
  end
end
