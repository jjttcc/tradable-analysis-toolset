require "test_helper"

describe TradableProcessorRun do
  let(:tradable_processor_run) { TradableProcessorRun.new }

  it "must be valid" do
    value(tradable_processor_run).must_be :valid?
  end
end
