class PeriodTypeSpecValidator < ActiveModel::Validator
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

end
