class CreateTradableAnalyzers < ActiveRecord::Migration[5.0]
  def change
    create_table :tradable_analyzers do |t|
      t.text :name
      t.integer :event_id
      t.boolean :is_intraday
      t.references :mas_session, foreign_key: true

      t.timestamps
    end
  end
end
