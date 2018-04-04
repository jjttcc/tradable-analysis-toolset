require "test_helper"

=begin
# This was generated by the "rails generate model ..." command:
describe ParameterGroup do
  let(:parameter_group) { ParameterGroup.new }

  it "must be valid" do
    value(parameter_group).must_be :valid?
  end
end
=end

TEST_IND_NAME1 = 'foobar'
TEST_IND_NAME2 = 'barbar'
GROUP1_NAME    = 'paramgroup1'
GROUP2_NAME    = 'paramgroup2'

class ParameterGroupTest < ActiveSupport::TestCase
  def setup
    @user = users(:jimtest1)
    @group1 = @user.parameter_groups.create!(name: GROUP1_NAME)
    @group2 = @user.parameter_groups.create!(name: GROUP2_NAME)
    @tproc1 = TradableProcessor.create!(name: TEST_IND_NAME1,
                                       tp_type: 'indicator')
    @tproc2 = TradableProcessor.create!(name: TEST_IND_NAME2,
                                       tp_type: 'analyzer')
    @parameter1 = @group1.tradable_processor_parameters.create!(
      name: 'parameter1', value: '8', data_type: 'integer',
      tradable_processor_id: @tproc1.id)
    @parameter2 = @group1.tradable_processor_parameters.create!(
      name: 'parameter2', value: '22.5', data_type: 'real',
      tradable_processor_id: @tproc1.id)
    @parameter3 = @group1.tradable_processor_parameters.create!(
      name: 'parameter3', value: '101', data_type: 'integer',
      tradable_processor_id: @tproc2.id)
    @parameter4 = @group2.tradable_processor_parameters.create!(
      name: 'parameter4', value: '26', data_type: 'integer',
      tradable_processor_id: @tproc2.id)
    @parameter5 = @group1.tradable_processor_parameters.create!(
      name: 'parameter5', value: '42', data_type: 'integer',
      tradable_processor_id: @tproc2.id)
  end

  test "valid" do
    assert @group1.valid?
  end

  test "tpps by procname" do
    tpps = ParameterGroup.parameters_by_uid_group_and_proc_name(
      @user.id, GROUP1_NAME, TEST_IND_NAME1)
    assert tpps.count == 2
    assert (tpps.select { |p| p.name == 'parameter1' }.count > 0)
    assert (tpps.select { |p| p.name == 'parameter2' }.count > 0)
    assert (tpps.select do |p|
      ['parameter3', 'parameter4', 'parameter5'].include?(p.name)
    end.count == 0)
  end

  test "group2: tpps by procname: empty" do
    tpps = ParameterGroup.parameters_by_uid_group_and_proc_name(
      @user.id, GROUP2_NAME, TEST_IND_NAME1)
    assert tpps.count == 0
  end

end