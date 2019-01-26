require "test_helper"

describe SymbolList do
  let(:symbol_list) { SymbolList.new }

  it "must be valid" do
    value(symbol_list).must_be :valid?
  end
end
