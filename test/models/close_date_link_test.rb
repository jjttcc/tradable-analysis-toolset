require "test_helper"

describe CloseDateLink do
  let(:close_date_link) { CloseDateLink.new }

  it "must be valid" do
    value(close_date_link).must_be :valid?
  end
end
