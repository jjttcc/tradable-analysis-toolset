class CreateMasSessions < ActiveRecord::Migration
  def change
    create_table :mas_sessions do |t|
      t.integer :user_id
      t.integer :mas_session_key

      t.timestamps
    end
  end
end
