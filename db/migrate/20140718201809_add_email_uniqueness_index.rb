class AddEmailUniquenessIndex < ActiveRecord::Migration
  def up
    add_index :users, :email_addr, :unique => true
  end

  def down
    remove_index :users, :email_addr
  end
end
