require "test_helper"
require_relative "model_helper"

describe TradableSymbol do
  let(:tradable_symbol) { TradableSymbol.new }

  it "must be valid" do
    value(tradable_symbol).must_be :valid?
  end
end

class TradableSymbolTest < ActiveSupport::TestCase

  def test_tracked
    symbols = ['IBM', 'F', 'RHT']
    new_track_count = 0
    symbols.each do |s|
      # Make sure these 3 are untracked.
      ts = TradableSymbol.find_by_symbol(s)
      if VERBOSE then
        puts "before - #{s} tracking count: #{ts.tracking_count}"
        puts "#{ts} is tracked?: #{ts.tracked?}"
      end
      if ! ts.nil? then
        ts.untrack!
      end
    end
    orig_track_count = TradableSymbol.tracked.count
    ModelHelper::track_tradables(symbols) do
      new_track_count = TradableSymbol.tracked.count
          symbols.each do |s|
            ts = TradableSymbol.find_by_symbol(s)
            assert ts.tracked?, "#{s} should be tracked"
            if VERBOSE then
              puts "during - #{s} tracking count: #{ts.tracking_count}"
              puts "#{ts} is tracked?: #{ts.tracked?}"
            end
          end
    end
    newest_track_count = TradableSymbol.tracked.count
    symbols.each do |s|
      ts = TradableSymbol.find_by_symbol(s)
      if VERBOSE then
        puts "after - #{s} tracking count: #{ts.tracking_count}"
        puts "#{ts} is tracked?: #{ts.tracked?}"
      end
    end
    puts "new_track_count: #{new_track_count}" if VERBOSE
    assert new_track_count > 0, 'new count > 0'
    assert new_track_count > orig_track_count, 'track count changed'
    assert new_track_count > newest_track_count
  end

end
