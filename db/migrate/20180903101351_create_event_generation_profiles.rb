class CreateEventGenerationProfiles < ActiveRecord::Migration[5.0]
  def change
    create_table :event_generation_profiles do |t|
      t.references :analysis_profile, foreign_key: true
      t.datetime :end_date
      t.integer :analysis_period_length_seconds

      t.timestamps
    end
  end
end
