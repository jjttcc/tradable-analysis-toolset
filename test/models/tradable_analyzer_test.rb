require "test_helper"

describe TradableAnalyzer do
  let(:tradable_analyzer) { TradableAnalyzer.new }

  it "must be valid" do
    value(tradable_analyzer).must_be :valid?
  end
end
