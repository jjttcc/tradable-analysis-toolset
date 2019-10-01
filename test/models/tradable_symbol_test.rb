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
    symbols = ['IBM', 'F', 'GOOG']
    new_tracked_count = 0
    symbols.each do |s|
      # Make sure these 3 are untracked.
      ts = TradableSymbol.find_by_symbol(s)
      if VERBOSE then
        puts "before - #{s} tracked: #{ts.tracked}"
        puts "#{ts} is tracked?: #{ts.tracked?}"
      end
      if ! ts.nil? then
        ts.untrack!
      end
    end
    orig_tracked_count = TradableSymbol.tracked_tradables.count
    ModelHelper::track_tradables(symbols) do
      new_tracked_count = TradableSymbol.tracked_tradables.count
          symbols.each do |s|
            ts = TradableSymbol.find_by_symbol(s)
            assert ts.tracked?, "#{s} should be tracked"
            if VERBOSE then
              puts "during - #{s} tracked: #{ts.tracked}"
              puts "#{ts} is tracked?: #{ts.tracked?}"
            end
          end
    end
    newest_tracked_count = TradableSymbol.tracked_tradables.count
    symbols.each do |s|
      ts = TradableSymbol.find_by_symbol(s)
      if VERBOSE then
        puts "after - #{s} tracked: #{ts.tracked}"
        puts "#{ts} is tracked?: #{ts.tracked?}"
      end
    end
    if VERBOSE; puts "new_tracked_count: #{new_tracked_count}" end
    assert new_tracked_count > 0, 'new count > 0'
    assert new_tracked_count > orig_tracked_count, 'track count changed'
    assert new_tracked_count > newest_tracked_count
  end

  # Test a TradableSymbol as a Tradable.
  def test_tradable
    symbols = ['IBM', 'F', 'GOOG']
    names = ["Business\s*Machines", "Ford\s*Motor", "Alphabet"]
    (0..symbols.count-1).each do |i|
      ts = TradableSymbol.find_by_symbol(symbols[i])
      assert ! ts.nil? && ts.is_a?(TAT::Tradable),
        "#{ts} should be a tradable but is not (#{ts.inspect})"
      assert ! ts.symbol.nil? && ts.symbol == symbols[i],
        "#{ts.symbol.inspect} should have a valid symbol value (#{ts.inspect})"
      assert ! ts.name.nil? && ts.name =~ /#{names[i]}/,
        "#{ts} should have a valid name (#{ts.name}) [#{names[i]}]"
    end
  end

end
