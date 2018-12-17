class CreateAddressAssignments < ActiveRecord::Migration[5.0]
  def change
    create_table :address_assignments do |t|
      t.references :address_user, polymorphic: true, index:
        {:name => "index_address_assignments_on_address_user_type_and_id"},
        null: false
      t.references :notification_address, index: true, foreign_key: true,
        null: false

      t.timestamps
    end
  end
end
