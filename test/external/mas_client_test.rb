require_relative '../test_helper'
require_relative '../models/model_helper'
require_relative '../helpers/analysis_specification'
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
  # (To-do: Add/test "PeriodicTrigger"s)
  def test_triggered_analysis
    symbol = 'ibm'
    analysis_setup([symbol])
    analyzer = Analysis.new($analysis_client)
    checker = TriggeredAnalysisCheck.new(nil)
    analyzer.add_observer(checker)
    triggers = $analysis_spec.triggers
    begin
    triggers.each do |t|
      assert ! t.new_record?, 'trigger must be in database'
      change_params(t, $analysis_client, false)
      puts "trigger t - activated, status (#{__LINE__}):"
      puts "#{t.activated}, #{t.status}"
      puts "trigger t: #{t} (#{t.inspect})"
      analyzer.run_triggered_analysis(t)
    end
    rescue StandardError => e
      assert false, "analysis failed [#{e}\n#{e.backtrace}]"
    end
  end

  # Test analysis runs "triggered" "by the user" via AnalysisProfile objects.
  def test_profile_analysis
    symbol = 'ibm'
    analysis_setup([symbol])
    analyzer = Analysis.new($analysis_client)
    checker = ProfileAnalysisCheck.new(nil)
    analyzer.add_observer(checker)
    users = $analysis_spec.users
    users.each do |u|
      assert ! u.new_record?, 'user must be in database'
      assert u.analysis_profiles.count > 0, 'user has >= 1 profile'
      u.analysis_profiles.each do |p|
        assert ! p.new_record?, 'profile must be in database'
        change_params(p, $analysis_client, false)
        analyzer.run_analysis_on_profile(p)
      end
    end
  end

  # Test analysis runs "triggered" by *Trigger objects with two different
  # TP-parameters settings and check that the results differ.
  def test_triggered_analysis_with_param_mod
    symbol = 'ibm'
    param_analysis_setup([symbol])
    analyzer = Analysis.new($analysis_client)
    checker = ParameterModCheck.new
    analyzer.add_observer(checker)
    triggers = $analysis_spec.triggers
    triggers.each do |t|
      assert ! t.new_record?, 'trigger must be in database'
      change_params(t, $analysis_client, false)
      puts "trigger t - activated, status (#{__LINE__}):"
      puts "#{t.activated}, #{t.status}"
      puts "trigger t: #{t} (#{t.inspect})"
      analyzer.run_triggered_analysis(t)
    end
    triggers.each do |t|
      t.reset
      assert ! t.new_record?, 'trigger must be in database'
      change_params(t, $analysis_client, true)
      puts "trigger t - activated, status (#{__LINE__}):"
      puts "#{t.activated}, #{t.status}"
      puts "trigger t: #{t} (#{t.inspect})"
      analyzer.run_triggered_analysis(t)
    end
  end

  # Test analysis runs "triggered" by *Trigger objects with two different
  # TP-parameters settings and check that the results differ.
  # Similar to test_triggered_analysis_with_param_mod, but with more than 1
  # analyzer and more than 1 symbol
#!!!!remove setup:...????!!!!
  def test_triggered_multi_symbol_analyzer_with_param_mod(setup: true)
    sym1 = 'ibm'; sym2 = 'jnj'
    symbols = [sym1, sym2]
    if setup then
      puts "setting up - param_analysis_setup"
      param_analysis_setup(symbols)
    else
      puts "NOT SETTING UP - param_analysis_setup"
    end
    analyzer = Analysis.new($analysis_client)
    checker = ParameterModCheck.new(counts: [
      {sym1 => [2], sym2 => [4]},
      {sym1 => [5], sym2 => [3]},
      {sym1 => [3], sym2 => [5]},
      {sym1 => [6], sym2 => [12]}])
    analyzer.add_observer(checker)
    triggers = $analysis_spec.triggers
    puts "PROCing triggers " +
      "[test_triggered_multi_symbol_analyzer_with_param_mod]"
    triggers.each do |t|
      assert ! t.new_record?, 'trigger must be in database'
      change_params(t, $analysis_client, false)
      puts "trigger t - activated, status (#{__LINE__}):"
      puts "#{t.activated}, #{t.status}"
      puts "trigger t: #{t} (#{t.inspect})"
      analyzer.run_triggered_analysis(t)
    end
    puts "PROCing2 triggers " +
      "[test_triggered_multi_symbol_analyzer_with_param_mod]"
    triggers.each do |t|
      t.reset
      assert ! t.new_record?, 'trigger must be in database'
      change_params(t, $analysis_client, true)
      puts "trigger t - activated, status (#{__LINE__}):"
      puts "#{t.activated}, #{t.status}"
      puts "trigger t: #{t} (#{t.inspect})"
      analyzer.run_triggered_analysis(t)
    end
  end

  protected

  ### Setup

  def analysis_setup(symbols)
    $analysis_user = User.find_by_email_addr(ANA_USER)
    if $analysis_user.nil? then
      $analysis_user = ModelHelper::new_user_saved(ANA_USER)
    end
    $analysis_client = MasClientTools::mas_client(user: $analysis_user,
                                             next_port: false)
    $analysis_spec = AnalysisSpecification.new([$analysis_user], symbols,
                                               false, false)
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

  ### Implementation - utilities

end
