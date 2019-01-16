
class AnalysisSpecification
  include Contracts::DSL, PeriodTypeConstants

  public

  attr_reader :triggers, :users

  private

  ANA_SCHEDULE     = 'mas-client-test-schedule'
  ANA_PROF1        = 'mas-client-test-profile1'
  ANA_PROF2        = 'mas-client-test-profile2'
  USER_PROF1       = 'mas-client-test-user-profile1'
  USER_PROF2       = 'mas-client-test-user-profile2'
  PARAM_PROF1      = 'mas-client-test-param-profile1'
  PARAM_PROF2      = 'mas-client-test-param-profile2'

  PROC_ID          =  2
  PROC_NAME        =  '<slot-for-obsolete-name-attribute>'
  PARAM_NAME       =  'n-value'
  PARAM_TYPE       =  'integer'
  OLD_PARAM_VALUES =  ['13','29','13','29','9']
  NEW_PARAM_VALUES =  ['5','11','5','11','5']
  DAY_SECS         =  24            *       60        *  60
  FIVE_DAYS        =  DAY_SECS      *       5
  DAYS_725         =  DAY_SECS      *       725
  THRESHOLD_FOR    =   {
    USER_PROF1     =>  12,
    USER_PROF2     =>  37,
  }
  SECS_FOR         =   {
    USER_PROF1     =>  DAY_SECS            *    565,
    USER_PROF2     =>  DAY_SECS            *    1565,
    ANA_PROF1      =>  DAY_SECS            *    54,
    ANA_PROF2      =>  DAY_SECS            *    66,
    PARAM_PROF1    =>  DAY_SECS            *    74,
    PARAM_PROF2    =>  DAY_SECS            *    197,
  }
  END_DATE_FOR     =   {
    USER_PROF1     =>  DateTime.new(2018,  01,  01),
    USER_PROF2     =>  DateTime.new(2015,  01,  01),
    ANA_PROF1      =>  DateTime.new(2012,  01,  01),
    ANA_PROF2      =>  DateTime.new(2012,  01,  01),
    PARAM_PROF1    =>  DateTime.new(2008,  12,  31),
    PARAM_PROF2    =>  DateTime.new(2014,  12,  31),
  }

  def initialize(users, skip_params = false, param_test = false)
    empty_db
    @users = users
    @triggers = activated_triggers
    @triggers.concat(periodic_triggers)
    if @triggers.empty? then
      # No triggers found in DB - Make a new one.
      @triggers = []
      @triggers << ModelHelper::new_eb_trigger(activated: true)
      @triggers[0].EOD_US_stocks!
      schedule = ModelHelper::new_schedule_for(users[0], ANA_SCHEDULE,
                                               @triggers[0], true)
      if param_test then
        profile1 = full_profile_params(PARAM_PROF1, schedule)
        profile2 = full_profile_params(PARAM_PROF2, schedule)
      else
        profile1 = full_profile(ANA_PROF1, schedule, skip_params)
        profile2 = full_profile(ANA_PROF2, schedule, skip_params)
      end
    end
    if ! param_test && users[0].analysis_profiles.count < 9 then
      uprofile1 = users_profile(USER_PROF1, users[0], skip_params)
      uprofile2 = users_profile(USER_PROF2, users[0], skip_params)
    end
  end

  # An AnalysisProfile, owned by schedule, with the expected associations:
  # an EventGenerationProfile, which has a TradableProcessorSpecification,
  # which has a TradableProcessorParameter.
  def full_profile(name, schedule, skip_param = false)
    result = ModelHelper::new_profile_for_schedule(schedule, name)
    secs = SECS_FOR[name]; enddate = END_DATE_FOR[name]
    eg_profile = ModelHelper::evgen_profile_for(result, enddate, secs)
    tp_spec = ModelHelper::tradable_proc_spec_for(eg_profile, PROC_ID, DAILY_ID)
    param = ModelHelper::tradable_proc_parameter_for(tp_spec, "",
      OLD_PARAM_VALUES[0], PARAM_TYPE, 1)
    result
  end

  # For TradableProcessorParameter test - An AnalysisProfile, owned by
  # schedule, with the expected associations:
  # an EventGenerationProfile, which has a TradableProcessorSpecification,
  # which has a TradableProcessorParameter.
  def full_profile_params(name, schedule)
    result = ModelHelper::new_profile_for_schedule(schedule, name)
    secs = SECS_FOR[name]; enddate = END_DATE_FOR[name]
    eg_profile = ModelHelper::evgen_profile_for(result, enddate, secs)
    tp_spec = ModelHelper::tradable_proc_spec_for(eg_profile, PROC_ID, DAILY_ID)
    param = ModelHelper::tradable_proc_parameter_for(tp_spec, "",
      OLD_PARAM_VALUES[0], PARAM_TYPE, 1)
    result
  end

  # An AnalysisProfile, owned by user, with the expected associations:
  # an EventGenerationProfile, which has a TradableProcessorSpecification,
  # which has a TradableProcessorParameter.
  def users_profile(name, user, skip_param = false)
    result = ModelHelper::new_profile_for_user(user, name)
    secs = SECS_FOR[name]; enddate = END_DATE_FOR[name]
    eg_profile = ModelHelper::evgen_profile_for(result, enddate, secs)
    tp_spec = ModelHelper::tradable_proc_spec_for(eg_profile, PROC_ID, DAILY_ID)
    param = ModelHelper::tradable_proc_parameter_for(tp_spec, "",
      OLD_PARAM_VALUES[0], PARAM_TYPE, 1)
    result
  end

  # "activated" (for the purposes of this test) triggers - i.e., ready to
  # trigger an analysis
  def activated_triggers
    result = EventBasedTrigger.all.select do |t|
      t.activated && t.analysis_schedules.count > 0
    end
    result
  end

  # periodic triggers - i.e., whose trigger time has occurred
  # (Stub)
  def periodic_triggers
    result = PeriodicTrigger.all.select do |t|
      ####Stub
    end
    result
  end

end

class AnalysisCheck < MiniTest::Test

  public

  def check_all_events(analyzer, profile, expected_threshold)
    all_events = analyzer.resulting_events
    assert all_events != nil, '"events" exists'
    $log.debug("Total of #{all_events.count} resulting events")
#!!!!! true(ueueu????)!!!!
assert true || all_events.count == expected_threshold, "unexpected number of " +
      "analysis events (#{all_events.count}, expected: #{expected_threshold})"
    if all_events.count > 0 then
      all_events.each do |e|
        assert_kind_of TradableEventInterface, e
        assert_respond_to e, :date_time, '"e" is missing "date_time"'
        assert_respond_to e, :signal_type, '"e" is missing "signal_type"'
        assert_kind_of String, e.event_type
        assert e.datetime != nil, 'valid datetime'
      end
    end
  end

  def check_events(analyzer, profile, expected_count)
    assert ! expected_count.nil? && expected_count >= 0,
      "expected_count invalid: '#{expected_count}'"
    runs = profile.last_analysis_runs
    assert runs.all? { |r| ! r.new_record? },
      "analysis runs have been saved to the database"
    if ! analyzer.error then
      assert runs.all? { |r|
        AnalysisRun.find(r.id).completed?
      }, "successful analysis runs are expected to be 'completed'"
    else
      puts "(analysis failed: #{analyzer.error_message}}"
      assert runs.all? { |r|
        # (failed? OR running? because a failed DB transaction could mean
        # the DB did not get updated as expected)
        AnalysisRun.find(r.id).failed? || AnalysisRun.find(r.id).running?
      }, "failed analysis runs are expected to be 'failed'"
    end
    runs.each do |r|
      events = r.all_events
      assert events != nil, '"events" exists'
      $log.debug("Total of #{events.count} resulting events")
      $log.debug("[check_events] analyzer: #{analyzer}")
      $log.debug("profile: #{profile.inspect}")
      $log.debug("count: #{events.count}")
      $log.debug("expected_count: #{expected_count}")
#!!!!! true(ueueu????)!!!!
assert true || events.count == expected_count, "unexpected number of " +
        "analysis events (#{events.count}, expected: #{expected_count})"
      if events.count > 0 then
        events.each do |e|
          assert ! e.new_record?, "Must be saved to DB: #{e}"
          assert_kind_of TradableEventInterface, e
          assert_kind_of String, e.event_type
          assert e.datetime != nil, 'valid datetime'
        end
      end
    if ! (defined? KEEP_DATA && KEEP_DATA) then
      r.destroy   # (Clean up before next test run.)
    end
    end
  end

  def check_events_by_symbol(analyzer, profile, threshold_map)
    assert ! threshold_map.nil? && threshold_map.count > 0,
      "threshold_map invalid: '#{threshold_map.inspect}'"
    runs = profile.last_analysis_runs
    assert runs.count > 0, 'at least 1 analysis run'
    assert runs.all? { |r| ! r.new_record? },
      "analysis runs have been saved to the database"
    if ! analyzer.error then
      assert runs.all? { |r|
        AnalysisRun.find(r.id).completed?
      }, "successful analysis runs are expected to be 'completed'"
    else
      puts "(analysis failed: #{analyzer.error_message}}"
      assert runs.all? { |r|
        # (failed? OR running? because a failed DB transaction could mean
        # the DB did not get updated re the 'failed' status)
        AnalysisRun.find(r.id).failed? || AnalysisRun.find(r.id).running?
      }, "failed analysis runs are expected to be 'failed' or 'running'"
    end
    # Assume only 1 run for the test.
    r = runs[0]
    (0..r.tradable_processor_runs.count - 1).each do |i|
      tprun = r.tradable_processor_runs[i]
      assert ! tprun.processor_name.nil?  && ! tprun.processor_name.empty?,
        "TradableProcessorRun[#{tprun.processor_id}] proc name should exist"
      threshold_map.keys.each do |symbol|
        spec = threshold_map[symbol]
        events = tprun.events_for_symbol(symbol)
#!!!!! true(ueueu????)!!!!
assert true || events.count == spec[i],
          "unexpected number of analysis events for '#{symbol}' " +
          "(#{events.count}, expected: #{spec[i]})"
        if events.count > 0 then
          events.each do |e|
            assert ! e.new_record?, "Must be saved to DB: #{e}"
            assert_kind_of TradableEventInterface, e
            assert_kind_of String, e.event_type
            assert e.datetime != nil, 'valid datetime'
          end
        end
      end
    end
    if ! (defined? KEEP_DATA && KEEP_DATA) then
      r.destroy   # (Clean up before next test run.)
    end
  end

  private

end

class TriggeredAnalysisCheck < AnalysisCheck

  THRESHOLD_FOR = {
    AnalysisSpecification::ANA_PROF1 => 2,
    AnalysisSpecification::ANA_PROF2 => 5
  }

  # Notification callback from Observable
  def update(analyzer, profile)
    assert profile.class == AnalysisProfile, 'expected class'
    assert profile.analysis_client != nil, 'profile has client'
    assert profile.event_generation_profiles != nil &&
      profile.event_generation_profiles.count > 0, 'profile has EGPs'
    check_all_events(analyzer, profile, THRESHOLD_FOR[profile.name])
  end

end

class ParameterModCheck < TriggeredAnalysisCheck

  OLD_THRESHOLD_FOR = {
    AnalysisSpecification::PARAM_PROF1 => 2,
    AnalysisSpecification::PARAM_PROF2 => 5
  }
  NEW_THRESHOLD_FOR = {
    AnalysisSpecification::PARAM_PROF1 => 3,
    AnalysisSpecification::PARAM_PROF2 => 6
  }

  # Notification callback from Observable
  def update(analyzer, profile)
    assert profile.class == AnalysisProfile, 'expected class'
    assert profile.analysis_client != nil, 'profile has client'
    assert profile.event_generation_profiles != nil &&
      profile.event_generation_profiles.count > 0, 'profile has EGPs'
    if ! @checked[profile] then
      threshold = OLD_THRESHOLD_FOR[profile.name]
      if ! @overridden_thresholds.empty? then
        threshold = @overridden_thresholds[@update_count]
      end
      if threshold.class == Hash then
        check_events_by_symbol(analyzer, profile, threshold)
      else
        check_events(analyzer, profile, threshold)
      end
      @checked[profile] = true
    else
      threshold = NEW_THRESHOLD_FOR[profile.name]
      if ! @overridden_thresholds.empty? then
        threshold = @overridden_thresholds[@update_count]
      end
      if threshold.class == Hash then
        check_events_by_symbol(analyzer, profile, threshold)
      else
        check_events(analyzer, profile, threshold)
      end
    end
    @update_count += 1
  end

  def initialize(*args)
    @checked = {}
    @overridden_thresholds = []
    @update_count = 0
    if args.count > 0 && args[0].keys.first == :counts then
      @overridden_thresholds = args[0].values.first
    end
    super(nil)
  end

end

class ProfileAnalysisCheck < AnalysisCheck

  # Notification callback from Observable
  def update(analyzer, profile)
    assert profile.class == AnalysisProfile, 'correct type for profile'
    assert profile.analysis_client != nil, 'profile has client'
    assert profile.event_generation_profiles != nil &&
      profile.event_generation_profiles.count > 0, 'profile has EGPs'
    check_events(analyzer, profile,
                 AnalysisSpecification::THRESHOLD_FOR[profile.name])
  end
end

def empty_db
  [AnalysisEvent, AnalysisProfile, AnalysisRun, AnalysisProfileRun,
   AnalysisSchedule, TradableEventSet, TradableProcessorParameterSetting,
   EventBasedTrigger, TradableProcessorParameter, EventGenerationProfile,
   TradableProcessorRun, TradableProcessorSpecification,
   PeriodicTrigger].each do |model|
    model.all.each { |record| record.destroy }
  end
end

# TradableProcessorSpecification objects associated with 't'
def specs_for_trigger(t)
  result = []
  t.analysis_schedules.each do |s|
    s.analysis_profiles.each do |p|
      p.event_generation_profiles.each do |egp|
        result.concat(egp.tradable_processor_specifications)
      end
    end
  end
  result
end

# TradableProcessorSpecification objects associated with AnalysisProfile 'p'
def specs_for_profile(p)
  result = []
  p.event_generation_profiles.each do |egp|
    result.concat(egp.tradable_processor_specifications)
  end
  result
end

def change_params(owner, mas_client, use_new_values = false)
  if owner.class == AnalysisProfile then
    specs = specs_for_profile(owner)
  else
    specs = specs_for_trigger(owner)
  end
  specs.each do |s|
    assert s.name != nil && ! s.name.empty?, "spec must have a valid name"
    mas_client.request_analysis_parameters(s.name, s.period_type_name)
    params_from_mas = mas_client.analysis_parameters
    if use_new_values then
      param_values = AnalysisSpecification::NEW_PARAM_VALUES
      # Set existing TradableProcessorParameter to new values.
      (0 .. param_values.count - 1).each do |i|
        p = s.tradable_processor_parameters[i]
        p.value = param_values[i]
      end
      s.save
    else
      # "TradableProcessorParameter"s don't exist yet - create/add them.
      param_values = AnalysisSpecification::OLD_PARAM_VALUES
      (1 .. param_values.count).each do |seqno|
        param = ModelHelper::tradable_proc_parameter_for(s,
            params_from_mas[seqno - 1].name, param_values[seqno - 1],
            AnalysisSpecification::PARAM_TYPE, seqno)
      end
    end
    s.tradable_processor_parameters.each do |p|
      mas_client.request_analysis_parameters_modification(
        s.name, s.period_type_name, "#{p.sequence_number}:#{p.value}")
    end
    mas_client.request_analysis_parameters(s.name, s.period_type_name)
    updated_params_from_mas = mas_client.analysis_parameters
    param_with_seqno = {}
    s.tradable_processor_parameters.each do |p|
      param_with_seqno[p.sequence_number] = p
    end
    # Check that the params updated in the server match those currently
    # stored in the database:
    position = 1
    updated_params_from_mas.each do |p|
      param = param_with_seqno[position]
      assert param != nil, "param #{position} present"
      assert param.name == p.name, "correct name [" +
        "'#{param.name}' should be '#{p.name}']"
      assert param.data_type == p.type_desc[0..param.data_type.length-1],
        "(at pos #{position}) correct data_type ['#{param.data_type}' " +
        "should be included in '#{p.type_desc}']"
      assert param.value == p.value, "(at pos #{position}) correct value [" +
        "'#{param.value}' should be '#{p.value}']"
      position += 1
    end
    assert ! (mas_client.communication_failed || mas_client.server_error),
      "error reported from server #{mas_client.last_error_msg}"
  end
end

# contents of AnalysisProfile 'p'
def profile_guts(p)
  result = ""
  if p.event_generation_profiles.count > 0 then
    result = "evgen-profiles: "
  end
  p.event_generation_profiles.each do |egp|
    result += "#{egp.inspect}, "
  end
  if p.analysis_profile_runs.count > 0
    result += "analysis-profile-runs: "
  end
  p.analysis_profile_runs.each do |apr|
    result += "#{apr.inspect}, " +
      ana_profile_run_guts(apr)
  end
  if p.notification_addresses.count > 0
    result += "notification-addresses: "
  end
  p.notification_addresses.each do |na|
    result += "#{na.inspect}, "
  end
  if p.notifications.count > 0
    result += "notifications: "
  end
  p.notifications.each do |n|
    result += "#{n.inspect}, "
  end
  result
end

# contents of AnalysisProfileRun 'r'
def ana_profile_run_guts(r)
  result = ""
  if r.analysis_runs.count > 0 then
    result = "analysis-runs: "
  end
  r.analysis_runs.each do |ar|
    result += "#{ar.inspect}:"
    result += '   ' + analysis_run_guts(ar) + ', '
  end
  result
end

# contents of AnalysisRun 'r'
def analysis_run_guts(r)
  result = ""
  if r.tradable_processor_runs.count > 0 then
    result = "TP-runs: "
  end
  r.tradable_processor_runs.each do |tpr|
    result += "#{tpr.inspect}:"
    result += '   ' + tradproc_run_guts(tpr) + ', '
  end
  result
end

# contents of TradableProcessorRun 'r'
def tradproc_run_guts(r)
  ""
end
