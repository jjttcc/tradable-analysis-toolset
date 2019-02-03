require "test_helper"

describe Exchange do
  let(:exchange) { Exchange.new }

  it "must be valid" do
    value(exchange).must_be :valid?
  end
end
