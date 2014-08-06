require 'test_helper'
require 'test_controller_helper'

class PeriodTypeSpecsControllerTest < ActionController::TestCase
  include TestControllerHelper
  include PeriodTypeConstants

  #### not signed-in ####

  def test_create_not_signed_in
    post :create
    assert_redirected_to signin_path
  end

  def test_destroy_not_signed_in
    delete :destroy, :id => 1
    assert_redirected_to signin_path
  end

  #### signed-in ####

  BAD_PTS_ATTRS = {
    :period_type_id => DAILY_ID,
    :start_date => nil,
    :end_date => nil
  }
  GOOD_PTS_ATTRS = {
    :period_type_id => DAILY_ID,
    :start_date => DateTime.yesterday,
    :end_date => nil
  }

  ## failure ##

  def test_create_failure_not_created
    user = signed_in_user
    oldcount = PeriodTypeSpec.count
    post :create, :period_type_spec => BAD_PTS_ATTRS
    assert PeriodTypeSpec.count == oldcount, 'count not changed'
  end

  ## success ##

  def test_create
    user = signed_in_user
    post :create, :period_type_spec => GOOD_PTS_ATTRS
    assert_redirected_to user_path(user.id)
  end

  def test_create_one_more
    user = signed_in_user
    oldcount = PeriodTypeSpec.count
    post :create, :period_type_spec => GOOD_PTS_ATTRS
    assert PeriodTypeSpec.count == oldcount + 1, 'created one'
  end

  def test_destroy
    user = signed_in_user
    pspec = Factory(:period_type_spec, :user => user)
    delete :destroy, :id => pspec.id
    assert_redirected_to user_path(user.id)
  end

  def test_destroy_one_less
    user = signed_in_user
    pspec = Factory(:period_type_spec, :user => user)
    oldcount = PeriodTypeSpec.count
    delete :destroy, :id => pspec.id
    assert PeriodTypeSpec.count == oldcount - 1, 'removed one'
  end

  def test_destroy_wrong_user
    user = signed_in_user
    wrong_user = Factory(:user, :email_addr => 'wrong-ptype-user@users.org')
    pspec = Factory(:period_type_spec, :user => user)
    signed_in_user(wrong_user)  # Force "wrong_user" to be signed in.
    oldcount = PeriodTypeSpec.count
    # (pspec belongs to user [not wrong_user], so should not be deleted.)
    delete :destroy, :id => pspec.id
    assert PeriodTypeSpec.count == oldcount, 'nothing deleted'
  end

end
