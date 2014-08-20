require "test_helper"
require 'test_controller_helper'

class ChartsControllerTest < ActionController::TestCase
  include TestControllerHelper

  def test_index_without_login
    get :index
    assert_redirected_to signin_path
  end

  def test_index_with_login_no_params
    user = signed_in_user
    get :index
    assert_redirected_to root_path
  end

  def test_index_with_invalid_params
    user = signed_in_user
    get :index, foo: 'stuff'
    assert_redirected_to root_path
  end

  def test_index_with_invalid_params2
    user = signed_in_user
    get :index, symbol: 'stuff'
    assert_redirected_to root_path
  end

  def test_index_with_valid_params
    user = signed_in_user
    get :index, symbol: 'ibm'
    assert_response :success
  end

  def test_index_with_valid_params2
    user = signed_in_user
    get :index, symbol: 'ibm', period_type: PeriodTypeConstants::WEEKLY
    assert_response :success
  end

end
