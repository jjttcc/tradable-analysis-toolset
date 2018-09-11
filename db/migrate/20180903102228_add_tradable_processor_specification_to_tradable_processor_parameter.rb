class AddTradableProcessorSpecificationToTradableProcessorParameter < ActiveRecord::Migration[5.0]
  def change
    add_reference :tradable_processor_parameters, :tradable_processor_specification,
      foreign_key: true,
      index: {:name => "index_trad_proc_params_on_tradable_processor_specification_id"}
  end
end
