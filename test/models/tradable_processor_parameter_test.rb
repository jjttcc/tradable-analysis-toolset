require "test_helper"

=begin
# This was generated by the "rails generate model ..." command:
describe TradableProcessorParameter do
  let(:tradable_processor_parameter) { TradableProcessorParameter.new }

  it "must be valid" do
    value(tradable_processor_parameter).must_be :valid?
  end
end
=end

class TradableProcessorParameterTest < ActiveSupport::TestCase

  def setup
    @user = users(:jimtest1)
=begin
#!!!!rm-me:!!!!
    @group1 = @user.parameter_groups.create!(name: 'paramgroup1')
    @parameter1 = @group1.tradable_processor_parameters.create!(
      name: 'parameter1', value: '8', data_type: 'integer')
=end
  end

  test "valid" do
return   #!!!!!!!!!!!!fix, please
    assert @parameter1.valid?
  end

  test "param group id NOT!!! required" do
return   #!!!!!!!!!!!!fix, please
    @parameter1.parameter_group_id = nil
    assert_not @parameter1.valid?
  end

  test "name should be present" do
return   #!!!!!!!!!!!!fix, please
    @parameter1.name = "   "
    assert_not @parameter1.valid?
  end

  test "value should be present" do
return   #!!!!!!!!!!!!fix, please
    @parameter1.value = "   "
    assert_not @parameter1.valid?
  end

  test "data_type should be present" do
return   #!!!!!!!!!!!!fix, please
    @parameter1.data_type = "   "
    assert_not @parameter1.valid?
  end

  test "data_type should not be too long" do
return   #!!!!!!!!!!!!fix, please
    @parameter1.data_type = 'floating point'
    assert_not @parameter1.valid?
  end

  test "data_type should be 'integer' or 'real'" do
return   #!!!!!!!!!!!!fix, please
    @parameter1.data_type = 'float'
    assert_not @parameter1.valid?
  end

  test "valid value" do
return   #!!!!!!!!!!!!fix, please
    @parameter1.value = 'all-foobar'
    assert_not @parameter1.valid?, "value: #{@parameter1.value}"
  end

end
