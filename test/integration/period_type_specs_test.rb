require "test_helper"

class PeriodTypeSpecsTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  def setup
    @user = signed_in_user
  end

  def test_create_default_fields
    oldcount = PeriodTypeSpec.count
    visit new_period_type_spec_path
    click_button 'Submit'
    assert PeriodTypeSpec.count == oldcount + 1, 'one created'
  end

end
