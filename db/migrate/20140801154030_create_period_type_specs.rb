class CreatePeriodTypeSpecs < ActiveRecord::Migration

  def up
    execute <<-SQL
      CREATE TABLE "period_type_specs" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "period_type_id" integer,
      "start_date" datetime,
      "end_date" datetime,
      "user_id" integer,
      "created_at" datetime NOT NULL,
      "updated_at" datetime NOT NULL,
      FOREIGN KEY (period_type_id) REFERENCES period_types(period_type_id)
      )
    SQL
    execute <<-SQL
      CREATE INDEX "index_period_type_specs_on_user_id" ON "period_type_specs" ("user_id")
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX "index_period_type_specs_on_user_id"
    SQL
    execute <<-SQL
      DROP TABLE "period_type_specs"
    SQL
  end

end
