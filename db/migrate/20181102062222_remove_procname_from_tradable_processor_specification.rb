class RemoveProcnameFromTradableProcessorSpecification < ActiveRecord::Migration[5.0]
  def change
    remove_column :tradable_processor_specifications, :processor_name, :string
  end
end
