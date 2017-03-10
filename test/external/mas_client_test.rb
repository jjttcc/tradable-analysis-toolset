require_relative '../test_helper'
require 'ruby_contracts'

class MasClientTest < MiniTest::Test
  include Contracts::DSL

  TESTPORT = 5441

  def new_logged_in_client
    result = MasClientOptimized.new(host: 'localhost', port: TESTPORT,
                                     factory: TradableObjectFactory.new)
  end

  def setup
    $client = new_logged_in_client
  end

  def teardown
    if $client.logged_in then $client.logout end
  end

  def test_create_client
    client = new_logged_in_client
    assert client != nil, 'MAS client object created.'
    assert client.logged_in, 'logged in'
    client.logout
    assert ! client.logged_in, 'logged out'
  end

  # (Assumption: 'ibm' symbol is always present.)
  def test_symbols
    $client.request_symbols
    symbols = $client.symbols
    assert symbols.length > 0
    symbol = 'ibm'
    assert (symbols.include? symbol), "Missing symbol #{symbol}"
  end

  def test_analyzer_list
    $client.request_analyzers("ibm", MasClient::DAILY)
    analyzers = $client.analyzers
    assert analyzers.class == [].class, "analyzers is an array"
    assert analyzers.length > 0, 'Some analyzers'
    analyzers.each do |a|
      assert_kind_of TradableAnalyzer, a
    end
  end

end
