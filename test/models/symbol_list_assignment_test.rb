require "test_helper"

describe SymbolListAssignment do
  let(:symbol_list_assignment) { SymbolListAssignment.new }

  it "must be valid" do
    value(symbol_list_assignment).must_be :valid?
  end
end
