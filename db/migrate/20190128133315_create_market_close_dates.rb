class CreateMarketCloseDates < ActiveRecord::Migration[5.0]
  def change
    create_table :market_close_dates do |t|
      t.integer :year,   null: false
      t.integer :month,  null: false
      t.integer :day,    null: false
      t.string  :reason, null: false

      t.index [:year, :reason], unique: true
      t.timestamps
    end
  end
end
