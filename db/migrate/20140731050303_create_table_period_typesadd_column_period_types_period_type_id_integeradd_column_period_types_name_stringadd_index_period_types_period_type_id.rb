class CreateTablePeriodTypesaddColumnPeriodTypesPeriodTypeIdIntegeraddColumnPeriodTypesNameStringaddIndexPeriodTypesPeriodTypeId < ActiveRecord::Migration

   def self.up

      create_table :period_types

      add_column :period_types,:period_type_id,:integer

      add_column :period_types,:name,:string

      add_index :period_types,:period_type_id,:unique => true

   end

   def self.down
     #waiting for reversible migrations in rails 3.1!
   end

end
