class CreateAnalysisSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :analysis_schedules do |t|
      t.string :name
      t.boolean :active
      t.references :trigger, polymorphic: true,
        index: {:name => "index_analysis_schedules_on_trigger_type_and_id"}
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
