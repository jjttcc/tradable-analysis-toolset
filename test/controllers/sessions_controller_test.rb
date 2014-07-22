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

  def setup
    @good_attr, @bad_attr, @good_user = setup_test_user
  end

  ### UNsuccessful login

  def test_bad_values
    post :create, :session => @bad_attr
    assert_response :success, 'normal response expected'
    assert_select 'title', /sign in/i, 'expected title'
    assert flash.now[:error] != nil && flash.now[:error] =~ /invalid/i,
      "flash error msg expected"
  end

  ### successful login

  def test_good_redirect
    post :create, :session => @good_attr
    assert_redirected_to user_path(@good_user), "successful login redirect"
    assert @controller.signed_in?, 'signed in'
  end

  ### successful logout

  def test_logout
    post :create, :session => @good_attr
    delete :destroy
    assert_redirected_to root_path, "successful logout completion"
    assert ! @controller.signed_in?, 'signed out'
  end

end
