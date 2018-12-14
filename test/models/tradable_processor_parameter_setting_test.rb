require "test_helper"

describe TradableProcessorParameterSetting do
  let(:tradable_processor_parameter_setting) { TradableProcessorParameterSetting.new }

  it "must be valid" do
    value(tradable_processor_parameter_setting).must_be :valid?
  end
end
