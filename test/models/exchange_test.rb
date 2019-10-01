require "test_helper"

describe Exchange do
  let(:exchange) { Exchange.new }

  it "must be valid" do
    value(exchange).must_be :valid?
  end
end

describe ExchangeClock do
  let(:eclock) { ExchangeClock.new }

  it "must be valid" do
    value(eclock.exchanges).must_be :present?
    value(eclock.initialization_time).must_be :present?
    value(eclock.current_date_time).must_be :present?
    assert eclock.tracked_tradables != nil, 'eclock.tracked_tradables not nil'
  end
end
