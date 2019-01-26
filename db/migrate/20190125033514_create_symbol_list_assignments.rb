class CreateSymbolListAssignments < ActiveRecord::Migration[5.0]
  def change
    create_table :symbol_list_assignments do |t|
      t.references :symbol_list_user, polymorphic: true, index:
        {name: :index_symbol_list_assignments_on_list_user_type_and_id},
        null: false
      t.references :symbol_list, index: true, foreign_key: true, null: false

      t.timestamps
    end
  end
end
