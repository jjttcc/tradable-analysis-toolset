require "test_helper"

describe PeriodicTrigger do
  let(:periodic_trigger) { PeriodicTrigger.new }

  it "must be valid" do
    value(periodic_trigger).must_be :valid?
  end
end
