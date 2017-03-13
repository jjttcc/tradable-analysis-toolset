require "test_helper"

describe Tradable do
  let(:tradable) { Tradable.new }

  it "must be valid" do
    value(tradable).must_be :valid?
  end
end
