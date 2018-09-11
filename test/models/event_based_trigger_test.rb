require "test_helper"

describe EventBasedTrigger do
  let(:event_based_trigger) { EventBasedTrigger.new }

  it "must be valid" do
    value(event_based_trigger).must_be :valid?
  end
end
