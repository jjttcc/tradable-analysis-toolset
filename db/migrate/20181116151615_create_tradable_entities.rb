class CreateTradableEntities < ActiveRecord::Migration[5.0]
  def change
    # (suppress creation of id primary key column)
    create_table :tradable_entities, id: false do |t|
      t.string :symbol, null: false
      t.string :name

      t.timestamps
    end

    # Effectively make :symbol the primary key:
    add_index :tradable_entities, :symbol, unique: true
  end
end
