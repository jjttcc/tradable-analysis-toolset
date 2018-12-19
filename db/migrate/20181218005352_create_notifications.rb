class CreateNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :notifications do |t|
      t.references :notification_source, polymorphic: true, index:
        {:name => "index_notifications_on_notification_source_type_and_id"},
        null: false
      t.integer :status, null: false
      t.string :error_message
      t.string :contact_identifier, null: false
      t.string :synopsis
      t.integer :medium_type, null: false
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
