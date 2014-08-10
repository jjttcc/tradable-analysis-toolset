require_relative '../test_helper'
require 'ruby_contracts'

class MasClientTest < MiniTest::Unit::TestCase
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
    $client.logout
  end

  def test_create_client
    client = new_logged_in_client
    assert client != nil, 'MAS client object created.'
  end

  # (Assumption: 'ibm' symbol is always present.)
  def test_symbols
    $client.request_symbols
    symbols = $client.symbols
    assert symbols.length > 0
    symbol = 'ibm'
    assert (symbols.include? symbol), "Missing symbol #{symbol}"
  end

end
