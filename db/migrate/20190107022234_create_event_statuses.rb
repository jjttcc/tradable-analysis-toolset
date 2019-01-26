class CreateEventStatuses < ActiveRecord::Migration[5.0]
  def change
    create_table :event_statuses do |t|
      t.string :name, null: false, unique: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
