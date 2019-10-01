require "test_helper"
require "tradable"

describe TradableEntity do
  let(:tradable_entity) { TradableEntity.new }

  it "must be valid" do
    value(tradable_entity).must_be :valid?
  end
end
