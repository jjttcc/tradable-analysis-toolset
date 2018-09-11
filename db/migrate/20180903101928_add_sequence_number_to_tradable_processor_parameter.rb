class AddSequenceNumberToTradableProcessorParameter < ActiveRecord::Migration[5.0]
  def change
    add_column :tradable_processor_parameters, :sequence_number, :integer
  end
end
