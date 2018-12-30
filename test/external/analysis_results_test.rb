AUTO_RUN_OFF = true
KEEP_DATA = true
require_relative '../models/notification_address_test.rb'
require_relative '../helpers/analysis_specification'

class AnalysisResultsTest < MiniTest::Test
  include Contracts::DSL

  TESTPORT = 5441
  TARGET_SYMBOL   = 'ibm'
  ANA_USER     = 'mas-client-testc@test.org'

  def new_logged_in_client
    result = MasClientNonblocking.new(host: 'localhost', port: TESTPORT,
                                     factory: TradableObjectFactory.new)
  end

  def setup
    $client = new_logged_in_client
    if TradableAnalyzer.all.count <= 2 then
      # Force the "tradable analyzers" to be retrieved from the MAS server
      # and saved to the database.
      $client.request_analyzers(TARGET_SYMBOL, MasClient::DAILY)
      analyzers = $client.analyzers
    end
  end

  def teardown
    if $client.logged_in then $client.logout end
    ModelHelper::cleanup
  end

  def test_notifications_1
    @notif_addr_test = NotificationAddressTest.new(nil)
    assert ! @notif_addr_test.nil?
    param_analysis_setup
    profs = AnalysisProfile.all
    assert profs.count == 2, '2 profiles'
    scheds = AnalysisSchedule.all
    assert scheds.count == 1, '1 schedules'
    s, p1, p2 = @notif_addr_test.test_3_used_addresses_by_3_addrusers_mix(
      scheds[0], profs[0], profs[1])
    assert s == scheds[0], 'schedule'
    assert p1 == profs[0], 'profile 1'
    assert p2 == profs[1], 'profile 2'
    setup_and_run_analysis
    assert AnalysisRun.all.count > 0, 'runs'
    assert AnalysisProfileRun.all.count > 0, 'runs'
    processor = AnalysisResultsProcessor.new
    processor.execute
    check_notification_results([p1, p2])
  end

  def check_notification_results(profiles)
    pruns = []
    profiles.each do |p|
      assert p.analysis_profile_runs.count > 0, '> 0'
      assert p.analysis_profile_runs.count == 1, '== 1'
      p.analysis_profile_runs.each do |r|
        if r.has_events? then
          if p.notification_addresses.count > 0 then
            assert r.notifications.count > 0,
              "r (#{r.inspect}) should have notifications, but DOESN'T."
            r.notifications.each do |n|
              assert ! n.new_record?,
                "notification #{n.inspect} must be in database"
              assert n.sent? || n.delivered? || n.failed?,
                "notification was 'sent', 'delivered', or 'failed'." +
                " (#{n.status})"
            end
          end
        end
      end
      pruns << p.analysis_profile_runs[0]
    end
    assert pruns.count == profiles.count, '1 analysis_profile_run per profile'
    pruns.each do |pr|
      assert pr.all_events.count > 0, "pr #{pr} has some events"
    end
  end

  def setup_and_run_analysis
    sym1 = 'ibm'; sym2 = 'jnj'
    analyzer = Analysis.new($analysis_client)
    checker = ParameterModCheck.new(counts: [
      {sym1 => [2], sym2 => [4]},
      {sym1 => [5], sym2 => [3]},
      {sym1 => [3], sym2 => [5]},
      {sym1 => [6], sym2 => [12]}])
    analyzer.add_observer(checker)
    symbols = [sym1, sym2]
    triggers = $analysis_spec.triggers
    triggers.each do |t|
      #assert ! t.new_record?, 'trigger must be in database'
      change_params(t, $analysis_client, false)
      analyzer.run_triggered_analysis(t, symbols)
    end
  end

  def analysis_setup
    $analysis_user = User.find_by_email_addr(ANA_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(ANA_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user],
                                               false, true)
  end

  def param_analysis_setup
    $analysis_user = User.find_by_email_addr(ANA_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(ANA_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user],
                                               false, true)
  end

end
