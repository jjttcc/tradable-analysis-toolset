class MakeTPnameUniqueAndAddNameIndexToPg < ActiveRecord::Migration[5.0]
  def change
    add_index :parameter_groups, :name
    add_index :tradable_processors, :name, unique: true
  end
end
