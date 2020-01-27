require 'ruby_contracts'
require 'eod_data_wrangler'

class TestEODDataWrangler < EODDataWrangler

  private

  ##### Test stub implementation

  class TestStorageManager
    include Contracts::DSL, TatServicesFacilities

    public

    def update_data_stores(symbols:)
      # Simply pick one randomly to "update and store":
      i = rand(symbols.count)
      if @stored[symbols[i]] then
        raise "Defect: '#{__method__}' called redundantly for #{symbols[i]}"
      end
      @stored[symbols[i]] = true
      test "#{__method__} 'stored' #{symbols[i]}"
    end

    def data_up_to_date_for(symbol, enddate)
      result = @stored[symbol]
      test "#{__method__} symbol, result: #{symbol}, #{result}"
      result
    end

    private

    attr_reader :error_log

    def initialize(elog)
      @stored = {}
      @error_log = elog
    end
  end

  def new_data_storage_manager
    test "#{__method__} creating a TestStorageManager"
    TestStorageManager.new(error_log)
  end

  def configured_seconds_between_update_tries
    0.33333
  end

end
