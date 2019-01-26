require "test_helper"

describe EventStatus do
  let(:event_status) { EventStatus.new }

  it "must be valid" do
    value(event_status).must_be :valid?
  end
end
