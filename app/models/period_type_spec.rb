#require 'period_type_constants'

class MyValidator < ActiveModel::Validator
  PTID = 'period_type_id'
  SDATE = 'start_date'
  EDATE = 'end_date'

  def validate(record)
    if record[PTID] == nil
      record.errors[PTID] << 'period-type id is nil'
    elsif ! valid_period_type_id(record[PTID])
      record.errors[PTID] << "period-type id - not a valid " +
        "value: #{record[PTID]}"
    end
    if record[SDATE] == nil
      record.errors[SDATE] << 'start date is nil'
    end
  end

  def valid_period_type_id(ptid)
    PeriodTypeConstants::ids.include?(ptid)
  end

  def work(record)
puts "MV - start_date: #{record[:start_date]}"
puts "MV - end_date: #{record[:end_date]}"
puts "MV - end_date class: #{record[:end_date].class}"
puts "MV - user_id: #{record[:user_id]}"
  end
end


class PeriodTypeSpec < ActiveRecord::Base
  include ActiveModel::Validations

  belongs_to :user
  attr_accessible :start_date, :end_date, :period_type_id
  validates_with MyValidator

  public

  def period_type_name
    query = "select pt.name from period_type_specs pts, period_types pt " +
            "where pt.period_type_id = #{period_type_id}"
    query = "select name from period_types " +
            "where period_type_id = #{period_type_id}"
puts "query: '#{query}'"
#"SELECT p.title, c.author FROM posts p, comments c WHERE p.id = c.post_id"
    result = PeriodTypeSpec.find_by_sql(query)
p 'period_type_name - result:', result
    result
  end

end
