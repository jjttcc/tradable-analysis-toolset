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

  def hide___test_notifications_1
    @notif_addr_test = NotificationAddressTest.new(nil)
    symbols = ['ibm', 'jnj']
    assert ! @notif_addr_test.nil?
    param_analysis_setup(symbols)
    profs = AnalysisProfile.all
    assert profs.count == 2, '2 profiles'
    scheds = AnalysisSchedule.all
    assert scheds.count == 1, '1 schedules'
    s, p1, p2 = @notif_addr_test.test_3_used_addresses_by_3_addrusers_mix(
      scheds[0], profs[0], profs[1])
    assert s == scheds[0], 'schedule'
    assert p1 == profs[0], 'profile 1'
    assert p2 == profs[1], 'profile 2'
    setup_and_run_analysis(symbols)
    assert AnalysisRun.all.count > 0, 'runs'
    assert AnalysisProfileRun.all.count > 0, 'runs'
    processor = AnalysisResultsProcessor.new
    processor.create_notifications
#sleep 3
    processor.perform_notifications
#sleep 0.75
    check_notification_results([p1, p2])
    # Test redundant requests.
    processor.create_notifications
    # (No notifications should be sent here:)
#sleep 1
    processor.perform_notifications
    # Results should not have changed.
    check_notification_results([p1, p2])
  end

  # Attempt to test that database locking is correctly implemented.
  def hideme___test_notifications_2__with_concurrency
    @notif_addr_test = NotificationAddressTest.new(nil)
    symbols = ['ibm', 'jnj']
    assert ! @notif_addr_test.nil?
    param_analysis_setup(symbols)
    profs = AnalysisProfile.all
    assert profs.count == 2, '2 profiles'
    scheds = AnalysisSchedule.all
    assert scheds.count == 1, '1 schedules'
    s, p1, p2 = @notif_addr_test.test_3_used_addresses_by_3_addrusers_mix(
      scheds[0], profs[0], profs[1])
    assert s == scheds[0], 'schedule'
    assert p1 == profs[0], 'profile 1'
    assert p2 == profs[1], 'profile 2'
    setup_and_run_analysis(symbols)
    assert AnalysisRun.all.count > 0, 'runs'
    assert AnalysisProfileRun.all.count > 0, 'runs'
    processor = AnalysisResultsProcessor.new
    redundantly_create_notifications(processor, 5)
#sleep 3
    redundantly_perform_notifications(processor, 5)
    check_notification_results([p1, p2])
    # Test redundant requests.
    processor.create_notifications
#sleep 1
    # (No notifications should be sent here:)
    processor.perform_notifications
    # Results should not have changed.
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
              assert n.sent? || n.delivered? || n.failed? || n.again?,
                "notification: 'sent', 'delivered', 'failed'," +
                " or again (#{n.status})"
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

  def setup_and_run_analysis(symbols)
    sym1 = symbols[0]; sym2 = symbols[1]
    analyzer = Analysis.new($analysis_client)
    checker = ParameterModCheck.new(counts: [
      {sym1 => [2], sym2 => [4]},
      {sym1 => [5], sym2 => [3]},
      {sym1 => [3], sym2 => [5]},
      {sym1 => [6], sym2 => [12]}])
    analyzer.add_observer(checker)
    triggers = $analysis_spec.triggers
    triggers.each do |t|
      #assert ! t.new_record?, 'trigger must be in database'
      change_params(t, $analysis_client, false)
      puts "trigger t - activated, status (#{__LINE__}):"
      puts "#{t.activated}, #{t.status}"
      puts "trigger t: #{t} (#{t.inspect})"
      analyzer.run_triggered_analysis(t)
    end
  end

  def analysis_setup(symbols)
    $analysis_user = User.find_by_email_addr(ANA_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(ANA_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user], symbols,
                                               false, true)
  end

  def param_analysis_setup(symbols)
    $analysis_user = User.find_by_email_addr(ANA_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(ANA_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user], symbols,
                                               false, true)
  end

  # Run 'processor.create_notifications' 'n' times concurrently.
  def redundantly_create_notifications(processor, n)
    threads = []
    n.times do |i|
      threads << Thread.new do
        begin
          processor.create_notifications
        rescue ActiveRecord::StaleObjectError => e
          puts "[#{__method__}] caught stale object exception - #{e})"
        rescue StandardError => e
          puts "[#{__method__}] caught generic exception - #{e})"
        end
      end
    end
    threads.map(&:join)
  end

  # Run 'processor.perform_notifications' 'n' times concurrently.
  def redundantly_perform_notifications(processor, n)
    threads = []
    n.times do |i|
      threads << Thread.new do
        begin
          processor.perform_notifications
        rescue ActiveRecord::StaleObjectError => e
          puts "[#{__method__}] caught stale object exception - #{e})"
        rescue StandardError => e
          puts "[#{__method__}] caught generic exception - #{e})"
        end
      end
    end
    threads.map(&:join)
  end
end
