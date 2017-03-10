# == Schema Information
#
# Table name: period_type_specs
#
#  id             :integer          not null, primary key
#  period_type_id :integer          not null
#  start_date     :datetime
#  end_date       :datetime
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  category       :string(255)
#

require "test_helper"
require_relative 'model_helper'

class PeriodTypeSpecTest < ActiveSupport::TestCase
  include PeriodTypeConstants
  include ModelHelper

  def setup
    @short_term = PeriodTypeSpec::SHORT_TERM
    @long_term = PeriodTypeSpec::LONG_TERM
  end

  def test_invariant
    period_type_spec = PeriodTypeSpec.new(period_type_id: ONE_MINUTE_ID,
      start_date: DateTime.now, end_date: DateTime.now,
      :category => @short_term)
    assert period_type_spec.invariant, 'PeriodTypeSpec invariant'
    period_type_spec = PeriodTypeSpec.new(period_type_id: ONE_MINUTE_ID,
      start_date: DateTime.now, end_date: DateTime.now,
      :category => @long_term)
    assert period_type_spec.invariant, 'PeriodTypeSpec invariant'
  end

  def test_broken_invariant
    period_type_spec = PeriodTypeSpec.new(period_type_id: ONE_MINUTE_ID,
      start_date: DateTime.now, end_date: DateTime.now,
      :category => 'gibberish')
    assert ! period_type_spec.invariant, 'PeriodTypeSpec violated invariant'
  end

  def test_valid_pts
    period_type_spec = PeriodTypeSpec.new(period_type_id: ONE_MINUTE_ID,
      start_date: DateTime.now, end_date: DateTime.now,
      :category => @short_term)
    assert period_type_spec.valid?, 'valid PeriodTypeSpec'
  end

  def test_null_enddate_ok
    period_type_spec = PeriodTypeSpec.new(period_type_id: HOURLY_ID,
      start_date: DateTime.now, end_date: nil,
      :category => @long_term)
    assert period_type_spec.valid?, 'null end-date is OK'
  end

  def test_no_sdate
    period_type_spec = PeriodTypeSpec.new(period_type_id: DAILY_ID,
      start_date: nil, end_date: DateTime.now,
      :category => @short_term)
    assert ! period_type_spec.valid?, 'null start-date should be invalid'
  end

  def test_invalid_sdate
    period_type_spec = PeriodTypeSpec.new(period_type_id: WEEKLY_ID,
      start_date: "not a good date", end_date: DateTime.now,
      :category => @long_term)
    assert ! period_type_spec.valid?, 'bad start-date should be invalid'
  end

  def test_invalid_period_type_id
    period_type_spec = PeriodTypeSpec.new(period_type_id: 67,
      start_date: DateTime.now,
      :category => @long_term)
    assert ! period_type_spec.valid?, 'period_type_id should be invalid'
  end

  def test_invalid_category
    period_type_spec = PeriodTypeSpec.new(period_type_id: ONE_MINUTE_ID,
      start_date: DateTime.now, end_date: DateTime.now,
      :category => 'irrelevant')
    assert ! period_type_spec.valid?, 'invalid category string'
    period_type_spec = PeriodTypeSpec.new(period_type_id: ONE_MINUTE_ID,
      start_date: DateTime.now, end_date: DateTime.now)
    assert ! period_type_spec.valid?, 'nil category'
  end

  def test_correct_ptype_name
    ids = PeriodTypeConstants.ids
    ids.each do |id|
      period_type_spec = PeriodTypeSpec.new(period_type_id: id,
        start_date: DateTime.now, :category => @long_term)
      assert period_type_spec.period_type_name ==
        PeriodTypeConstants.name_for[id], "correct name for #{id}"
    end
  end

  def test_period_types_with_mas_client
    user = ModelHelper::new_user('mas-pt-test@tests.org')
    user2 = ModelHelper::new_user('mas-pt-test2@tests.org')
    now = DateTime.now
    pts1 = create(:period_type_spec, user: user, end_date: nil)
    pts2 = create(:period_type_spec, user: user, period_type_id: WEEKLY_ID,
                   end_date: nil, start_date: now.dup.advance(years: -3))
    pts3 = create(:period_type_spec, user: user, period_type_id: MONTHLY_ID,
                   end_date: nil, start_date: now.dup.advance(years: -5))
    pts4 = create(:period_type_spec, user: user, period_type_id: QUARTERLY_ID,
                   end_date: nil, start_date: now.dup.advance(years: -15))
    pts5 = create(:period_type_spec, user: user, period_type_id: YEARLY_ID,
                   end_date: now.dup.advance(years: -14),
                   start_date: now.dup.advance(years: -35))
    styrly = pts5
    long_term = PeriodTypeSpec::LONG_TERM
    ltpts1 = create(:period_type_spec, user: user, end_date: nil,
                     category: long_term)
    ltpts2 = create(:period_type_spec, user: user, period_type_id: WEEKLY_ID,
                     end_date: nil, start_date: now.dup.advance(years: -3),
                     category: long_term)
    ltpts3 = create(:period_type_spec, user: user, period_type_id: MONTHLY_ID,
                     end_date: nil, start_date: now.dup.advance(years: -5),
                     category: long_term)
    ltpts4 = create(:period_type_spec, user: user,
                     period_type_id: QUARTERLY_ID,
                     end_date: now.dup.advance(years: -4),
                     start_date: now.dup.advance(years: -24),
                     category: long_term)
    ltpts5 = create(:period_type_spec, user: user, period_type_id: YEARLY_ID,
                     end_date: now.dup.advance(years: -14),
                     start_date: now.dup.advance(years: -104),
                     category: long_term)
    ltpts6 = create(:period_type_spec, user: user,
                   period_type_id: ONE_MINUTE_ID, end_date: nil,
                   start_date: now.dup.advance(days: -5),
                   category: long_term)
    ltweekly = ltpts2
    ltyrly = ltpts5
    sminute = ltpts6
    long_terms = []
    user.period_type_specs.each do |p|
      if p.category == long_term then long_terms << p end
    end
    user.save
    client = MasClientTools::mas_client_w_ptypes(long_terms)
    assert client.period_type_spec_for(WEEKLY) == ltweekly,
      'mas client has expected weekly period type spec'
    assert client.period_type_spec_for(YEARLY) != styrly,
      'mas client does NOT have sort-term yearly period type spec'
    assert client.period_type_spec_for(YEARLY) == ltyrly,
      'mas client has expected yearly period type spec'
    ltyrly2 = create(:period_type_spec, user: user2, period_type_id: YEARLY_ID,
                     end_date: now.dup.advance(years: -14),
                     start_date: now.dup.advance(years: -104),
                     category: long_term)
    client2 = MasClientTools::mas_client(user: user2)
    assert (client2.period_type_spec_for(YEARLY) == ltyrly2),
        "mas client 2 has long-term yearly period type spec"
    assert (client2.period_type_spec_for(YEARLY) != styrly),
        "mas client 2: no short-term yearly period type spec"
    assert ONE_MINUTE == '1-minute', "What's #{ONE_MINUTE}?"
    assert client.period_type_spec_for(ONE_MINUTE) == sminute,
      'mas client has expected 1-minute period type spec'
  end

end
