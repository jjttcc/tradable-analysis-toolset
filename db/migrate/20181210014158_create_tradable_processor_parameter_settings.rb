class CreateTradableProcessorParameterSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :tradable_processor_parameter_settings do |t|
      t.references :tradable_processor_run, foreign_key: true, null: false,
        index: {:name => "index_tradable_proc_param_settings_on_tradable_proc_run_id"}
      t.string :name, null: false
      t.string :value, null: false

      t.timestamps
    end
  end
end
