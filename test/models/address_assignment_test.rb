require "test_helper"

describe AddressAssignment do
  let(:address_assignment) { AddressAssignment.new }

  it "must be valid" do
    value(address_assignment).must_be :valid?
  end
end
