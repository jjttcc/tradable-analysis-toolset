require_relative '../test_helper'
require_relative '../models/model_helper'
require 'ruby_contracts'

class MasClientTest < MiniTest::Test
  include Contracts::DSL, PeriodTypeConstants

  TESTPORT = 5441
  TARGET_SYMBOL   = 'ibm'
  ANA_USER     = 'mas-client-testc@test.org'

  def new_logged_in_client
    result = MasClientNonblocking.new(host: 'localhost', port: TESTPORT,
                                     factory: TradableObjectFactory.new)
  end

  def setup
    $client = new_logged_in_client
  end

  def teardown
    if $client.logged_in then $client.logout end
    if $analysis_user then
      $analysis_user.delete
    end
  end

  def test_create_client
    client = new_logged_in_client
    assert client != nil, 'MAS client object created.'
    assert ! client.communication_failed && !  client.server_error,
      "server returned failure status"
    assert client.logged_in, 'logged in'
    client.logout
    assert ! client.logged_in, 'logged out'
  end

  def test_symbols
    $client.request_symbols
    assert ! $client.communication_failed && !  $client.server_error,
      "server returned failure status"
    symbols = $client.symbols
    assert symbols.length > 0
    symbol = TARGET_SYMBOL
    assert (symbols.include? symbol), "Missing symbol #{symbol}"
  end

  # Get the list of analyzers from the MAS server, save them to the
  # database.
  def test_analyzer_list
    $client.request_analyzers(TARGET_SYMBOL, MasClient::DAILY)
    assert ! $client.communication_failed && !  $client.server_error,
      "server returned failure status"
    analyzers = $client.analyzers
    assert analyzers.class == [].class, "analyzers is an array"
    assert analyzers.length > 0, 'Some analyzers'
    analyzers.each do |a|
      assert_kind_of TradableAnalyzer, a
      assert ! a.new_record?, "analyzer (#{a}) is NOT in the database."
    end
  end

  # Test analysis runs "triggered" by *Trigger objects.
  # (To-do: PeriodicTrigger test)
  def test_triggered_analysis
    analysis_setup
    analyzer = Analysis.new($analysis_client)
    checker = TriggeredAnalysisCheck.new(nil)
    analyzer.add_observer(checker)
    symbol = 'ibm'
    triggers = $analysis_spec.triggers
#####
    $analysis_client.request_analyzers(symbol, MasClient::DAILY)
    assert ! $analysis_client.communication_failed &&
      !  $analysis_client.server_error, "SERVER RETURNED FAILURE STATUS"
    analyzers = $analysis_client.analyzers
=begin
!!!To-do: Make sure that each TradableProcessorSpecification associated
with each member of 'triggers' matches one element of 'analyzers' (i.e.,
processor_id and processor_name matches the corresponding attributes of one
element of 'analyzers').
=end
    assert analyzers.length > 0, 'Some analyzers'
#####
    begin
    triggers.each do |t|
      assert ! t.new_record?, 'trigger must be in database'
      analyzer.run_triggered_analysis(t, symbol)
    end
    rescue StandardError => e
      assert false, "analysis failed [#{e}]"
    end
  end

  # Test analysis runs "triggered" "by the user" via AnalysisProfile objects.
  def test_profile_analysis
    analysis_setup
    analyzer = Analysis.new($analysis_client)
    checker = ProfileAnalysisCheck.new(nil)
    analyzer.add_observer(checker)
    symbol = 'ibm'
    users = $analysis_spec.users
    users.each do |u|
      assert ! u.new_record?, 'user must be in database'
      assert u.analysis_profiles.count > 0, 'user has >= 1 profile'
      u.analysis_profiles.each do |p|
        assert ! p.new_record?, 'profile must be in database'
        analyzer.run_analysis_on_profile(p, symbol)
      end
    end
  end

  # Test analysis runs "triggered" by *Trigger objects with two different
  # TP-parameters settings and check that the results differ.
  def test_triggered_analysis_with_param_mod
#!!!!!TO-DO: Force use of unchanging, past end-date.!!!!!!
    analysis_setup
    analyzer = Analysis.new($analysis_client)
    checker = ParameterModCheck.new(10, 23)
    analyzer.add_observer(checker)
    symbol = 'ibm'
    triggers = $analysis_spec.triggers
puts "run A:"
    triggers.each do |t|
      assert ! t.new_record?, 'trigger must be in database'
puts "testing trigger #{t.inspect} [run A]"
      change_params(t, $analysis_client, false)
      analyzer.run_triggered_analysis(t, symbol)
    end
puts "run B:"
    triggers.each do |t|
      assert ! t.new_record?, 'trigger must be in database'
puts "testing trigger #{t.inspect} [run B]"
      change_params(t, $analysis_client, true)
      analyzer.run_triggered_analysis(t, symbol)
    end
  end

  # Notification callback from Observable
  def update(analyzer, target)
puts "<<<<UPDATE>>> called"
raise "OBSOLETE, DUDE!"
    if
      target.class == EventBasedTrigger || target.class == PeriodicTrigger
    then
      puts "trigger analysis happened"
    else
      assert target.class == AnalysisProfile,
        "'target' should be AnalysisProfile"
      puts "profile analysis happened"
    end
    all_events = analyzer.resulting_events
    assert all_events != nil, '"events" exists'
    puts "Total of #{all_events.count} resulting events"
    expected_threshold = 25
    assert all_events.count > expected_threshold, "NOT:reasonable number of " +
      "analysis events (#{all_events.count}, expected > #{expected_threshold})"
    if all_events.count > 1 then
      all_events.each do |e|
        assert_kind_of TradableEventInterface, e
        assert_kind_of String, e.event_type
        assert e.datetime != nil, 'valid datetime'
      end
    end
  end

  private

  ### Setup

  def analysis_setup
    $analysis_user = User.find_by_email_addr(ANA_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(ANA_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user])
  end

  def analysis_setup_wo_params
    $analysis_user = User.find_by_email_addr(ANA_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(ANA_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user], true)
  end

  ### Implementation - utilities

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

  def change_params(t, mas_client, new = false)
    specs = specs_for_trigger(t)
    specs.each do |s|
      period_type = PeriodTypeConstants::name_for[s.period_type]
puts "sname, sptype: #{s.name}, #{period_type}"
mas_client.request_analysis_parameters(s.name, period_type) #!!!!!!!
puts "#{mas_client.analysis_parameters.count} params back from MAS server:"
mas_client.analysis_parameters.each do |p|
pp p
      end
puts "s's name: #{s.name}"
      if new then
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
            AnalysisSpecification::PARAM_NAME, param_values[seqno - 1],
            AnalysisSpecification::PARAM_TYPE, seqno)
        end
      end
      s.tradable_processor_parameters.each do |p|
        mas_client.request_analysis_parameters_modification(
          s.name, period_type, "#{p.sequence_number}:#{p.value}")
      end
#!!!!!Check for error!!!!!!
if mas_client.communication_failed || mas_client.server_error then
puts "[there was an ERROR!!!!!!]"
else
puts "[THERE WAS NO error!]"
end
puts "[ERROR MSG: #{mas_client.last_error_msg}]"
    end
  end

end

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

  PROC_ID          =  2
  PROC_NAME        =  '<slot-for-obsolete-name-attribute>'
  PARAM_NAME       =  'n-value'
  PARAM_TYPE       =  'integer'
  OLD_PARAM_VALUES =  ['12','26','12','26','6']
  NEW_PARAM_VALUES =  ['5','13','5','13','6']
  DAY_SECS         =  24            *       60        *  60
  FIVE_DAYS        =  DAY_SECS      *       5
  DAYS_725         =  DAY_SECS      *       725
  THRESHOLD_FOR    =   {
    USER_PROF1     =>  25,
    USER_PROF2     =>  50,
  }
  SECS_FOR         =   {
    USER_PROF1     =>  DAY_SECS            *    565,
    USER_PROF2     =>  DAY_SECS            *    1565,
  }
  END_DATE_FOR     =   {
    USER_PROF1     =>  DateTime.new(2018,  01,  01),
    USER_PROF2     =>  DateTime.new(2015,  01,  01),
  }

  def initialize(users, skip_params = false)
    @users = users
    @triggers = activated_triggers
    if @triggers.empty? then
      # No triggers found in DB - Make a new one.
      @triggers = []
      @triggers << ModelHelper::new_eb_trigger(active: true)
      @triggers[0].EOD_US_stocks!
      schedule = ModelHelper::new_schedule_for(users[0], ANA_SCHEDULE,
                                               @triggers[0])
      profile1 = full_profile(ANA_PROF1, schedule, skip_params)
      profile2 = full_profile(ANA_PROF2, schedule, skip_params)
    end
    if users[0].analysis_profiles.count < 9 then
      uprofile1 = users_profile(USER_PROF1, users[0], skip_params)
      uprofile2 = users_profile(USER_PROF2, users[0], skip_params)
    end
  end

  # An AnalysisProfile, owned by schedule, with the expected associations:
  # an EventGenerationProfile, which has a TradableProcessorSpecification,
  # which has a TradableProcessorParameter.
  def full_profile(name, schedule, skip_param = false)
    result = ModelHelper::new_profile_for_schedule(schedule, name)
    eg_profile = ModelHelper::evgen_profile_for(result, nil, DAYS_725)
    tp_spec = ModelHelper::tradable_proc_spec_for(eg_profile, PROC_ID,
                                               PROC_NAME, DAILY_ID)
    param = ModelHelper::tradable_proc_parameter_for(tp_spec, PARAM_NAME,
      OLD_PARAM_VALUES[0], PARAM_TYPE, 1)
    result
  end

  # An AnalysisProfile, owned by user, with the expected associations:
  # an EventGenerationProfile, which has a TradableProcessorSpecification,
  # which has a TradableProcessorParameter.
  def users_profile(name, user, skip_param = false)
puts "UPPPPPPPPPPPPPPPPPPPPPPPPPP"
    result = ModelHelper::new_profile_for_user(user, name)
    secs = SECS_FOR[name]; enddate = END_DATE_FOR[name]
    eg_profile = ModelHelper::evgen_profile_for(result, enddate, secs)
    tp_spec = ModelHelper::tradable_proc_spec_for(eg_profile, PROC_ID,
                                               PROC_NAME, DAILY_ID)
    param = ModelHelper::tradable_proc_parameter_for(tp_spec, PARAM_NAME,
      OLD_PARAM_VALUES[0], PARAM_TYPE, 1)
    result
  end

  # "activated" (for the purposes of this test) triggers - i.e., ready to
  # trigger an analysis
  def activated_triggers
    result = EventBasedTrigger.all.select do |t|
      t.active && t.analysis_schedules.count > 0
    end
    result
  end

end

class AnalysisCheck < MiniTest::Test

  public

  def check_all_events(analyzer, target, expected_threshold)
puts "[cae] target: #{target.inspect}"  #!!!!!
    all_events = analyzer.resulting_events
    assert all_events != nil, '"events" exists'
    puts "Total of #{all_events.count} resulting events"
    assert all_events.count > expected_threshold, "NOT:reasonable number of " +
      "analysis events (#{all_events.count}, expected > #{expected_threshold})"
    if all_events.count > 0 then
      all_events.each do |e|
        assert_kind_of TradableEventInterface, e
        assert_kind_of String, e.event_type
        assert e.datetime != nil, 'valid datetime'
      end
    end
  end

  def check_events(analyzer, target, expected_threshold)
    event_gen_profs = target.event_generation_profiles
puts "target: #{target.inspect}"  #!!!!!
    events = event_gen_profs[0].last_analysis_results
    assert events != nil, '"events" exists'
    puts "Total of #{events.count} resulting events"
#!!!    expected_threshold = AnalysisSpecification::THRESHOLD_FOR[target.name]
puts "et for #{target.name}: #{expected_threshold}" #!!!!!
    assert events.count > expected_threshold, "NOT:reasonable number of " +
      "analysis events (#{events.count}, expected > #{expected_threshold})"
    if events.count > 0 then
      events.each do |e|
        assert_kind_of TradableEventInterface, e
        assert_kind_of String, e.event_type
        assert e.datetime != nil, 'valid datetime'
      end
    end
  end

end

class TriggeredAnalysisCheck < AnalysisCheck

  DEFAULT_THRESHOLD = 25

  # Notification callback from Observable
  def update(analyzer, profile)
    assert profile.class == AnalysisProfile, ''
    check_all_events(analyzer, profile, DEFAULT_THRESHOLD)
  end

end

class ParameterModCheck < TriggeredAnalysisCheck

  # Notification callback from Observable
  def update(analyzer, profile)
    assert profile.class == AnalysisProfile, ''
    if ! @checked[profile] then
puts "First time checking profile [#{profile}]"
      check_events(analyzer, profile, @old_threshold)
      @checked[profile] = true
    else
puts "Second time checking profile [#{profile}]"
      check_events(analyzer, profile, @new_threshold)
    end
  end

  def initialize(old_threshold, new_threshold)
    @checked = {}
    @old_threshold = old_threshold
    @new_threshold = new_threshold
    super(nil)
  end

end

class ProfileAnalysisCheck < AnalysisCheck

  # Notification callback from Observable
  def update(analyzer, profile)
    assert profile.class == AnalysisProfile, 'correct type for profile'
    check_events(analyzer, profile,
                 AnalysisSpecification::THRESHOLD_FOR[profile.name])
  end
end
