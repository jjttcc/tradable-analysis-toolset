class PeriodTypeSpecValidator < ActiveModel::Validator
  PTID = 'period_type_id'
  SDATE = 'start_date'
  EDATE = 'end_date'
  CATEGORY = 'category'

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
    if
      record[CATEGORY] == nil or
      ! PeriodTypeSpec::VALID_CATEGORY[record[CATEGORY]]
    then
      record.errors[CATEGORY] << 'invalid category'
    end
  end

  def valid_period_type_id(ptid)
    PeriodTypeConstants::ids.include?(ptid)
  end

end
