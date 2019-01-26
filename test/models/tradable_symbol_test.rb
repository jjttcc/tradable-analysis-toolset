require "test_helper"

describe TradableSymbol do
  let(:tradable_symbol) { TradableSymbol.new }

  it "must be valid" do
    value(tradable_symbol).must_be :valid?
  end
end
