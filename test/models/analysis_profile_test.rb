require "test_helper"
require_relative 'model_helper'

TEST_USER_ADDR = 'analysis-profile@tests.org'
PROFILE_NAME1  = 'profile 1'
PROFILE_NAME2  = 'profile 2'
FIVE_DAYS      = 25 * 60 * 60 * 5
PROC_ID        = 5
PARAM_NAME     = 'n-value'
PARAM_VALUE    = '13'
PARAM_TYPE     = 'integer'

class AnalysisProfileTest < ActiveSupport::TestCase
  include PeriodTypeConstants

  def init_database_with_user
    ModelHelper::new_user_saved(TEST_USER_ADDR)
  end

  def init_database_with_user_and_profile
    user = ModelHelper::new_user_saved(TEST_USER_ADDR)
    ModelHelper::new_profile_for_user(user, PROFILE_NAME1)
  end

  def test_new
    profile = AnalysisProfile.new
    value(profile).must_be :valid?
  end

  def test_profile_creation
    name = PROFILE_NAME1
    user = ModelHelper::new_user_saved(TEST_USER_ADDR)
    profile = ModelHelper::new_profile_for_user(user, name)
    assert user.analysis_profiles.include?(profile), 'user owns the profile'
    assert profile.name == name, 'profile - name set.'
  end

  def test_profile_retrieval
    init_database_with_user_and_profile
    name = PROFILE_NAME1
    user = User.find_by_email_addr(TEST_USER_ADDR)
    profile = AnalysisProfile.find_by_name(name)
    assert user.analysis_profiles.include?(profile), 'user owns the profile'
  end

  # Create a user's profile that is complete - i.e., has >= 1 of:
  # EventGenerationProfile, TradableProcessorSpecification,
  # TradableProcessorParameter.
  def test_part_of_scenario_1_complete_profile
    u = init_database_with_user
    profile = ModelHelper::new_profile_for_user(u, PROFILE_NAME1)
    eg_profile = ModelHelper::evgen_profile_for(profile, nil, FIVE_DAYS)
    spec = ModelHelper::tradable_proc_spec_for(eg_profile, PROC_ID, DAILY_ID)
    param = ModelHelper::tradable_proc_parameter_for(spec, PARAM_NAME,
                                                     PARAM_VALUE, PARAM_TYPE)
    value(u).must_be :valid?
    value(profile).must_be :valid?
    value(eg_profile).must_be :valid?
    value(spec).must_be :valid?
    value(param).must_be :valid?

    assert u.analysis_profiles.include?(profile), 'user owns the profile'
    assert profile.event_generation_profiles.include?(eg_profile),
      'profile includes the EventGenerationProfile'
    assert eg_profile.tradable_processor_specifications.include?(spec),
      'EventGenerationProfile includes the new spec'
    assert spec.tradable_processor_parameters.include?(param),
      'TradableProcessorSpecification includes "param"'
  end

end
