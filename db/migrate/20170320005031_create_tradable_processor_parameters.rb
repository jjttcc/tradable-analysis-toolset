class CreateTradableProcessorParameters < ActiveRecord::Migration[5.0]
  def change
    create_table :tradable_processor_parameters do |t|
      t.string :name
      t.string :value
      t.string :data_type
      t.references :parameter_group, foreign_key: true, index: true
      t.references :tradable_processor, foreign_key: true, index: true

      t.timestamps
    end
  end
end
