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
    get :index, params: { foo: 'stuff' }
    assert_redirected_to root_path
  end

  def test_index_with_invalid_params2
    user = signed_in_user
    get :index, params: { symbol: 'stuff' }
    assert_redirected_to root_path
  end

  def test_index_with_invalid_params3
    user = signed_in_user
    post :index, params: {
      symbol: 'ibm', period_type: PeriodTypeConstants::WEEKLY,
      startdate: { FOO: 'foo', BAR: 'bar' },
      enddate: { year: '', month: '', day: ''}}
    assert_redirected_to root_path
  end

  def test_index_with_valid_params
    user = signed_in_user
    get :index, params: { symbol: 'ibm',
      startdate: { year: '2013', month: '1', day: '7'},
      enddate: { year: '', month: '', day: ''}}
    assert_response :success
  end

  def test_index_with_valid_params2
    user = signed_in_user
    post :index, params: {
      symbol: 'ibm', period_type: PeriodTypeConstants::WEEKLY,
      startdate: { year: '2013', month: '1', day: '7'},
      enddate: { year: '', month: '', day: ''}}
    assert_response :success
  end

  def test_index_with_valid_params3
    user = signed_in_user
    get :index, params: { symbol: 'ibm' }
    assert_response :success
  end

end
