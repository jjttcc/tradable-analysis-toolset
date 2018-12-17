class CreateNotificationAddresses < ActiveRecord::Migration[5.0]
  def change
    create_table :notification_addresses do |t|
      t.references :user, foreign_key: true, null: false
      t.string :label, null: false, index: {unique: true}
      t.integer :medium_type, null: false
      t.string :contact_identifier, null: false
      t.string :extra_data

      t.timestamps
    end
  end
end
