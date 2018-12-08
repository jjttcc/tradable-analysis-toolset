class TradableProcessorSpecificationAddConstraintsNotNull < ActiveRecord::Migration[5.0]
  def change
    change_column :tradable_processor_specifications, :processor_id, :integer,
      null: false
    change_column :tradable_processor_specifications, :period_type, :integer,
      null: false
  end
end
