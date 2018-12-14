require "test_helper"

describe TradableEventSet do
  let(:tradable_event_set) { TradableEventSet.new }

  it "must be valid" do
    value(tradable_event_set).must_be :valid?
  end
end
