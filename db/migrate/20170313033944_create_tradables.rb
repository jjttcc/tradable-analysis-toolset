class CreateTradables < ActiveRecord::Migration[5.0]
  def change
    create_table :tradables do |t|
      t.text :name

      t.timestamps
    end
  end
end
