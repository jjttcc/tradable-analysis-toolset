require "test_helper"

describe MasSocketAddress do
  let(:mas_socket_address) { MasSocketAddress.new }

  it "must be valid" do
    value(mas_socket_address).must_be :valid?
  end
end
