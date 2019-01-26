class CreateMasSocketAddresses < ActiveRecord::Migration[5.0]
  def change
    create_table :mas_socket_addresses do |t|
      t.string :name
      t.string :fqdn, null: false, default: ""
      t.integer :port, null: false

      t.timestamps
    end
  end
end
