require "test_helper"

describe MarketCloseDate do
  let(:market_close_date) { MarketCloseDate.new }

  it "must be valid" do
    value(market_close_date).must_be :valid?
  end
end
