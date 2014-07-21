require "test_helper"

class UsersControllerTest < ActionController::TestCase

  ### GET 'new' ###

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

  ### GET 'show' ###

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

  ### POST 'create' ###

  def init_create
    @bad_attr = {
      :email_addr            => '',
      :password              => '',
      :password_confirmation => ''
    }
    @good_attr = {
      :email_addr            => 'foo@foo.org',
      :password              => 'passwordski',
      :password_confirmation => 'passwordski'
    }
  end

  def test_create_failure
    init_create
    old_user_count = User.count
    post :create, :user => @bad_attr
    assert User.count == old_user_count, "no added user records"
  end

  def test_create_success
    init_create
    old_user_count = User.count
    post :create, :user => @good_attr
    assert User.count == old_user_count + 1, "one more user record"
    user = User.find_by_email_addr(@good_attr[:email_addr])
    assert user != nil, "found newly added user"
  end

  def test_create_success_redirect
    init_create
    post :create, :user => @good_attr
    assert_redirected_to user_path(assigns(:user))
  end

  def test_create_welcome_flash
    init_create
    post :create, :user => @good_attr
    assert flash[:success] =~ /Welcome.*Toolset/, 'correct flash message'
  end

end
