require "test_helper"

describe TradableProcessorSpecification do
  let(:tradable_processor_specification) { TradableProcessorSpecification.new }

  it "must be valid" do
    value(tradable_processor_specification).must_be :valid?
  end
end
