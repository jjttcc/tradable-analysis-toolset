# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'period_type_constants'

connection = ActiveRecord::Base.connection()
count = connection.select_values(
  "select count(period_type_id) from period_types")
if count[0] == 0
  # Populate the period_types reference table.
  PeriodTypeConstants::ids.each do |id|
    connection.execute("insert into period_types (period_type_id, name) " +
                       "values (#{id}, '#{PeriodTypeConstants::name_for[id]}')")
  end
end
