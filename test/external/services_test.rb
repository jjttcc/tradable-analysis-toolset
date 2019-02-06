AUTO_RUN_OFF = true
KEEP_DATA = true
require_relative '../models/notification_address_test.rb'
require_relative '../helpers/analysis_specification'

class ServicesTest < MiniTest::Test
  include Contracts::DSL

  TESTPORT = 5441
  TARGET_SYMBOL   = 'ibm'
  ANA_USER     = 'mas-client-testc@test.org'

  def setup
  end

  def teardown
  end

  def test_db_fork_task
    require "rake"
    Rails.application.load_tasks
    Rake::Task['test_db_fork'].invoke
    assert true, 'no exception thrown'
  rescue Exception => e
    assert false, "exception caught - db-fork test  failed: #{e}"
  end

  def test_eod_retrieval
    apple = 'AAPL'; ford = 'F'
    symbols = [apple, ford]
    f_last_open = '8.7'
    f_penultimate_open = '8.77'
    f_penultimate_low = '8.62'
    startd, endd = '2019-01-30', '2019-02-04'
    data = eod_data(symbols, startd, endd)
    data.keys.each do |k|
      puts "data for #{k}:"
      data[k].each do |record|
        puts record.inspect
      end
    end
    assert data.has_key?(apple), "data for #{symbols[0]}"
    assert data.has_key?(ford), "data for #{symbols[1]}"
    assert data[apple].count == 4, "4 records for #{symbols[0]}"
    assert data[ford].count == 4, "4 records for #{symbols[1]}"
    ford_last_open = data[ford].last[1].to_f.to_s
    assert f_last_open == ford_last_open, 'Ford last open check'
    ford_penult_open = data[ford][-2][1].to_f.to_s
    ford_penult_low = data[ford][-2][3].to_f.to_s
    assert f_penultimate_open == ford_penult_open, 'Ford penultimate open check'
    assert f_penultimate_low == ford_penult_low, 'Ford penultimate low check'
  end

  def test_eod_updates
    symbols = ['IBM', 'RHT', 'PG']
    storage_manager = data_storage_manager
    storage_manager.remove_tail_records(symbols, 1)
    storage_manager.update_data_stores(symbols)
    symbols.each do |s|
      assert ! storage_manager.last_update_empty_for(s),
        "#{s}: expected > 0 records updated"
    end
  end

  def test_metadata_retrieval
    data_config = Rails.configuration.data_setup.call
    retriever = data_config.data_retriever
    apple = 'AAPL'; ford = 'F'
    retriever.retrieve_metadata_for(apple)
    meta = retriever.metadata_for[apple]
    name = retriever.name_for(apple)
    exchange = retriever.exchange_for(apple)
    description = retriever.description_for(apple)
    puts "name: #{name}\nexchange: #{exchange}\ndescription: #{description}"
    assert meta != nil, 'metadata exists'
    assert name != nil && name =~ /apple/i, 'correct name'
    assert exchange != nil && exchange == 'NASDAQ', 'correct exchange'
    assert description != nil, 'description exists'
  end

  private  ### Implementation - utilities

  def eod_data(symbols, startd, endd)
    data_config = Rails.configuration.data_setup.call
    retriever = data_config.data_retriever
    retriever.retrieve_ohlc_data(symbols, startd, endd)
    retriever.data_sets
  end

  def data_storage_manager
    data_config = Rails.configuration.data_setup.call
    data_config.data_storage_manager
  end

end
