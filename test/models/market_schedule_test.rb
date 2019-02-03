require "test_helper"

describe MarketSchedule do
  let(:market_schedule) { MarketSchedule.new }

  it "must be valid" do
    value(market_schedule).must_be :valid?
  end
end
