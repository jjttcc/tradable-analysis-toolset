class CreateTradableProcessorSpecifications < ActiveRecord::Migration[5.0]
  def change
    create_table :tradable_processor_specifications do |t|
      t.references :event_generation_profile, foreign_key: true,
        index: {:name => "index_tradable_processor_specs_on_event_generation_profile_id"}
      t.integer :processor_id
      t.string :processor_name
      t.integer :period_type

      t.timestamps
    end
  end
end
