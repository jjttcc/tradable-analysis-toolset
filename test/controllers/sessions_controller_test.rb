require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  ### 'new' ###

  def test_new
    get :new
    assert_response :success
  end

  def test_correct_title
    get :new
    assert_select 'title', /sign\s+in/i, 'sign-in title'
  end

  ### POST 'create' ###

  def setup
    @bad_attr = {:email_addr => '', :password => ''}
  end

  def test_bad_values
    post :create, :session => @bad_attr
    assert_response :success, 'normal response expected'
    assert_select 'title', /sign in/i, 'expected title'
    assert flash.now[:error] != nil && flash.now[:error] =~ /invalid/i,
      "flash error msg expected"
  end

end
