class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email_addr

      t.timestamps
    end
  end
end
