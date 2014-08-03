# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'period_type_constants'

connection = ActiveRecord::Base.connection()

if ENV['RAILS_ENV'] == "test"
  require 'test_constants'

  begin
    connection.execute('select 1 from period_type_specs limit 1')
    # (If the above succeeds, the table exists and will not be created.)
  rescue Exception
    connection.execute('
      CREATE TABLE "period_type_specs" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      "period_type_id" integer,
      "start_date" datetime,
      "end_date" datetime,
      "user_id" integer,
      "created_at" datetime NOT NULL,
      "updated_at" datetime NOT NULL,
      FOREIGN KEY (period_type_id) REFERENCES period_types(period_type_id)
      )'
    )
    connection.execute('CREATE INDEX "index_period_type_specs_on_user_id"
      ON "period_type_specs" ("user_id")'
    )
  end


  admin_email, nonadmin_email = TestConstants::ADMIN_EMAIL,
    TestConstants::NONADMIN_EMAIL
  admin_pw, nonadmin_pw = TestConstants::ADMIN_PW, TestConstants::NONADMIN_PW
  if User.find_by_email_addr(admin_email) == nil
    #### Ensure both an 'admin' and a non-admin user resides in the DB.
    user = User.create!(:email_addr => admin_email,
                        :password => admin_pw,
                        :password_confirmation => admin_pw)
    user.toggle!(:admin)
    user = User.create!(:email_addr => nonadmin_email,
                        :password => nonadmin_pw,
                        :password_confirmation => nonadmin_pw)
    a = User.find_by_email_addr(admin_email)
    u = User.find_by_email_addr(nonadmin_email)
    if a.nil? or u.nil?
      throw "failed to save admin or non-admin"
    end
  end
end

count = connection.select_values(
  "select count(period_type_id) from period_types")
if count[0] == 0
  # Populate the period_types reference table.
  PeriodTypeConstants::ids.each do |id|
    connection.execute("insert into period_types (period_type_id, name) " +
                       "values (#{id}, '#{PeriodTypeConstants::name_for[id]}')")
  end
end
