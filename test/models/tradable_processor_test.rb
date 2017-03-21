require "test_helper"

describe TradableProcessor do
  let(:tradable_processor) { TradableProcessor.new }

  it "must be valid" do
    value(tradable_processor).must_be :valid?
  end
end
