class CreateCloseDateLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :close_date_links do |t|
      t.references :market, polymorphic: true, null: false
      t.references :market_close_date, foreign_key: true, null: false

      t.timestamps
    end
  end
end
