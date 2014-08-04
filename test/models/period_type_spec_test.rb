# == Schema Information
#
# Table name: period_type_specs
#
#  id             :integer          not null, primary key
#  period_type_id :integer
#  start_date     :datetime
#  end_date       :datetime
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require "test_helper"

class PeriodTypeSpecTest < ActiveSupport::TestCase
  include PeriodTypeConstants

  def test_valid_pts
    period_type_spec = PeriodTypeSpec.new(period_type_id: ONE_MINUTE_ID,
      start_date: DateTime.now, end_date: DateTime.now)
    assert period_type_spec.valid?, 'valid PeriodTypeSpec'
  end

  def test_null_enddate_ok
    period_type_spec = PeriodTypeSpec.new(period_type_id: HOURLY_ID,
      start_date: DateTime.now, end_date: nil)
    assert period_type_spec.valid?, 'null end-date is OK'
  end

  def test_no_sdate
    period_type_spec = PeriodTypeSpec.new(period_type_id: DAILY_ID,
      start_date: nil, end_date: DateTime.now)
    assert ! period_type_spec.valid?, 'null start-date should be invalid'
  end

  def test_invalid_sdate
    period_type_spec = PeriodTypeSpec.new(period_type_id: WEEKLY_ID,
      start_date: "not a good date", end_date: DateTime.now)
    assert ! period_type_spec.valid?, 'bad start-date should be invalid'
  end

  def test_invalid_period_type_id
    period_type_spec = PeriodTypeSpec.new(period_type_id: 67,
      start_date: DateTime.now)
    assert ! period_type_spec.valid?, 'period_type_id should be invalid'
  end

  def test_correct_ptype_name
    ids = PeriodTypeConstants.ids
    ids.each do |id|
      period_type_spec = PeriodTypeSpec.new(period_type_id: id,
                                            start_date: DateTime.now)
      assert period_type_spec.period_type_name ==
        PeriodTypeConstants.name_for[id], "correct name for #{id}"
    end
  end

end