require "test_helper"
require_relative 'model_helper'

SCHEDULE_NAME1 = 'schedule 1'

PROFILE_NAME1  = 'profile 1'
PROFILE_NAME2  = 'profile 2'
FIVE_DAYS      = 25 * 60 * 60 * 5
PROC_ID        = 5
PARAM_NAME     = 'n-value'
PARAM_VALUE    = '13'
PARAM_TYPE     = 'integer'

class EventBasedTriggerTest < ActiveSupport::TestCase
  include PeriodTypeConstants

  def test_new
    trigger = EventBasedTrigger.new(activated: false)
    trigger.EOD_US_stocks!
    assert trigger.activated == false, "'activated' is false"
    assert trigger.EOD_US_stocks?, "tr-event-type is 'EOD_US_stocks'"
    value(trigger).must_be :valid?
  end

  def test_trigger_creation
    our_user = ModelHelper::new_user_saved('triggered-event-fanatic@tests.org')
    trigger = ModelHelper::new_eb_trigger
    trigger.EOD_US_stocks!
    schedule = ModelHelper::new_schedule_for(our_user, SCHEDULE_NAME1,
                                             trigger, true)
    profile1 = full_profile(PROFILE_NAME1, schedule)
    profile2 = full_profile(PROFILE_NAME2, schedule)

    value(our_user).must_be :valid?
    value(trigger).must_be :valid?
    value(schedule).must_be :valid?
    value(profile1).must_be :valid?
    value(profile2).must_be :valid?

    assert ! trigger.activated, 'trigger - supposed to default to ! activated.'
    assert trigger.analysis_schedules.include?(schedule),
      'trigger has the schedule'
    assert our_user.analysis_schedules.include?(schedule),
      'user has the schedule'
    assert schedule.analysis_profiles.include?(profile1),
      'schedule owns profile1'
    assert schedule.analysis_profiles.include?(profile2),
      'schedule owns profile2'
  end

  # An AnalysisProfile, owned by schedule, with the expected associations:
  # an EventGenerationProfile, which has a TradableProcessorSpecification,
  # which has a TradableProcessorParameter.
  def full_profile(name, schedule)
    result = ModelHelper::new_profile_for_schedule(schedule, name)
    eg_profile = ModelHelper::evgen_profile_for(result, nil, FIVE_DAYS)
    tp_spec = ModelHelper::tradable_proc_spec_for(eg_profile, PROC_ID, DAILY_ID)
    param = ModelHelper::tradable_proc_parameter_for(tp_spec, PARAM_NAME,
                                                     PARAM_VALUE, PARAM_TYPE)
    value(eg_profile).must_be :valid?
    value(tp_spec).must_be :valid?
    value(param).must_be :valid?

    assert result.event_generation_profiles.include?(eg_profile),
      'result (AnalysisProfile) includes the EventGenerationProfile'
    assert eg_profile.tradable_processor_specifications.include?(tp_spec),
      'EventGenerationProfile includes the new spec'
    assert tp_spec.tradable_processor_parameters.include?(param),
      'TradableProcessorSpecification includes "param"'
    result
  end

end
