class CreateMarketSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :market_schedules do |t|
      t.references :market, polymorphic: true
      t.integer :schedule_type, null: false, default: 1
      t.string :date
      t.string :pre_market_start_time
      t.string :pre_market_end_time
      t.string :post_market_start_time
      t.string :post_market_end_time
      t.string :core_start_time, null: false
      t.string :core_end_time, null: false

      t.timestamps
    end
  end
end
