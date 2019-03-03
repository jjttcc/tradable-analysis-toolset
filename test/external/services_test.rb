AUTO_RUN_OFF = true
KEEP_DATA = true
require_relative '../models/notification_address_test.rb'
require_relative '../helpers/analysis_specification'

class ServicesTest < MiniTest::Test
  include Contracts::DSL, TatServicesFacilities

  TESTPORT = 5441
  TARGET_SYMBOL   = 'ibm'
  ANA_USER     = 'mas-client-testc@test.org'

  def setup
  end

  def teardown
  end

  def hide___test_db_fork_task
    require "rake"
    Rails.application.load_tasks
    Rake::Task['test_db_fork'].invoke
    assert true, 'no exception thrown'
  rescue Exception => e
    assert false, "exception caught - db-fork test  failed: #{e}"
  end

  def hide___test_eod_retrieval
    apple = 'AAPL'; ford = 'F'
    symbols = [apple, ford]
    ModelHelper::track_tradables(symbols) do
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
      assert f_penultimate_open == ford_penult_open,
        'Ford penultimate open check'
      assert f_penultimate_low == ford_penult_low,
        'Ford penultimate low check'
    end
  end

  def hide___test_eod_updates
    symbols = ['IBM', 'RHT', 'PG']
    ModelHelper::track_tradables(symbols) do
      storage_manager = data_storage_manager
      storage_manager.remove_tail_records(symbols, 1)
      storage_manager.update_data_stores(symbols)
      symbols.each do |s|
        assert ! storage_manager.last_update_empty_for(s),
          "#{s}: expected > 0 records updated"
        assert storage_manager.last_update_count_for(s) >= 1,
          "#{s}: expected >= 1 records updated"
      end
    end
  end

  def test_eod_task
    require "rake"
    symbols = ['I', 'K', 'L']
#!!!symbols = ['x']
    ModelHelper::track_tradables(symbols) do
      config = data_config
      storage_manager = config.data_storage_manager
      channel = EOD_CHECK_CHANNEL
      # Cheat: Use the TradableStorage.remove_tail_records to make sure there
      # is an EOD record to retrieve:
      storage_manager.remove_tail_records(symbols, 1)
      Rails.application.load_tasks
#     Rake::Task['start_eod_service'].invoke(symbols)
      Rake::Task['test_eod'].invoke(channel, symbols)
    end
    assert true, 'no exception thrown'
  rescue Exception => e
    assert false, "exception caught - test_eod failed: #{e}"
  end

  def hide___test_metadata_retrieval
    config = data_config
    retriever = config.data_retriever
    apple, ford, ping_an_bank, suning = 'AAPL', 'F', '000001', '002024'
    symbols = [apple, ford, ping_an_bank, suning]
    names = ['Apple', 'Ford', 'Ping.An.Bank', 'Suning.Commerce.Group']
    exchanges = ['NASDAQ', 'NYSE', 'SHE', 'SHE']
    (0..symbols.count-1).each do |i|
      retriever.retrieve_metadata_for(symbols[i])
    end
    (0..symbols.count-1).each do |i|
      meta = retriever.metadata_for[symbols[i]]
      name = retriever.name_for(symbols[i])
      exchange = retriever.exchange_for(symbols[i])
      description = retriever.description_for(symbols[i])
      print "\nsymbol: #{symbols[i]}: "
      puts "name: #{name}\nexchange: #{exchange}\ndescription: #{description}"
      assert meta != nil, 'metadata exists'
      assert name != nil && name =~ /#{names[i]}/i, 'correct name'
      assert exchange != nil && exchange == exchanges[i], 'correct exchange'
      assert description != nil, 'description exists'
    end
  end

  private  ### Implementation - utilities

  def eod_data(symbols, startd, endd)
    config = data_config
    retriever = config.data_retriever
    retriever.retrieve_ohlc_data(symbols, startd, endd)
    retriever.data_sets
  end

  def data_storage_manager
    config = data_config
    result = config.data_storage_manager
    result
  end

  def data_config
    Rails.configuration.data_setup.call
  end

end
