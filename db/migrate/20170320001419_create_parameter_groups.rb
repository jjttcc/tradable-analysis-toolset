class CreateParameterGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :parameter_groups do |t|
      t.string :name
      t.references :user, foreign_key: true, index: true

      t.timestamps
    end
  end
end
