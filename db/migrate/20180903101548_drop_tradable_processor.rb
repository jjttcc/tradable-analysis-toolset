class DropTradableProcessor < ActiveRecord::Migration[5.0]
  def change
    remove_reference :tradable_processor_parameters, :tradable_processor, foreign_key: true, index: true
    # (Attempt to make it reversible.)
    drop_table :tradable_processors do |t|
      t.varchar "name"
      t.varchar "tp_type"
      t.timestamps null: false
      t.index :name
    end
  end
end
