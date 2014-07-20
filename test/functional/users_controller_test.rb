require "test_helper"

class UsersControllerTest < ActionController::TestCase

  ### new ###

  def test_new
    get :new
    assert_response :success
  end

  def test_correct_title
    get :new
    assert_select 'title', /Create.*login/
  end

  def test_correct_body
    get :new
    assert_select 'body', /Create.*login/
  end

  ### show ###

  def setup
    @user = Factory(:user)
  end

  def test_show
    get :show, :id => @user
    assert_response :success
  end

  def test_show_correct_user
    get :show, :id => @user.id
    assert assigns(:user) == @user, "correct user"
  end

  def test_show_correct_title
    get :show, :id => @user.id
    assert_select 'title', /#{@user.email_addr}/, 'correct title'
  end

  def test_show_correct_h1
    get :show, :id => @user.id
    assert_select 'h1', /#{@user.email_addr}/, 'correct h1'
  end

end
