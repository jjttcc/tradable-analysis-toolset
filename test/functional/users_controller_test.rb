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
    # Requre that contract-checking is enabled:
    if not ENV['ENABLE_ASSERTION']
      raise "ENABLE_ASSERTION environment variable needs to be set."
    end
    @stored_user1 = setup_test_user_with_eaddr('ibeuser1@users.org')[2]
    @stored_user2 = setup_test_user_with_eaddr('ibeuser2@users.org')[2]
    @stored_user3 = setup_test_user_with_eaddr('ibeuser3@users.org')[2]
    @user = @stored_user1
  end

  def test_show
    get :show, :id => signed_in_user
    assert_response :success
  end

  def test_show_correct_user
    user = signed_in_user
    get :show, :id => user.id
    assert assigns(:user) == user, "correct user"
  end

  def test_show_correct_title
    user = signed_in_user
    get :show, :id => user.id
    assert_select 'title', /#{user.email_addr}/, 'correct title'
  end

  def test_show_correct_h1
    user = signed_in_user
    get :show, :id => user.id
    assert_select 'h1', /#{user.email_addr}/, 'correct h1'
  end

  def test_show_not_logged_in
    get :show, :id => @user
    assert_redirected_to signin_path
  end

  ### GET 'index' ###

  def test_index
    get :index, :id => signed_in_user
    assert_response :success
  end

  def test_index_title
    @user = signed_in_user
    get :index
    assert_select 'title', /user\s+list/i
  end

  def test_find_stored_users
    @user = signed_in_user
    get :index
    User.all.each do |u|
      assert_select 'body', /#{u.email_addr}/, 'body contains user'
    end
  end

  def test_index_not_logged_in
    begin
      get :index
      assert_redirected_to signin_path
    rescue Contracts::Error => e
      puts "[caught expected contract violation: #{e}]"
    end
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

  def test_signed_in
    init_create
    post :create, :user => @good_attr
    assert @controller.signed_in?
  end

  ### GET 'edit' ###

  def signed_in_user(u = nil)
    if u != nil
      user = u
    else
    _, _, user = setup_test_user
    end
    @controller.sign_in(user)
    user
  end

  def sign_out
    @controller.sign_out
  end

  def test_begin_edit
    get :edit, :id => signed_in_user
    assert_response :success
  end

  def test_edit_title
    get :edit, :id => signed_in_user
    assert_select 'title', /Edit\s+user/
  end

  ### update ###

  GOOD_ATTRS1 = {
    :email_addr            => 'newtester@tester.org',
    :password              => 'newpwpwpw',
    :password_confirmation => 'newpwpwpw',
  }

  def test_bad_update
    _, badattr, user = setup_test_user
    @controller.sign_in(user)
    put :update, :id => user, :user => badattr
    assert_select 'title', /Edit\s+user/
  end

  def test_good_update
    user = signed_in_user
    put :update, :id => user, :user => GOOD_ATTRS1
    user.reload
    assert user.email_addr == GOOD_ATTRS1[:email_addr], 'emails match'
  end

  def test_update_flash
    put :update, :id => signed_in_user, :user => GOOD_ATTRS1
    assert flash[:success] =~ /Updated/i, 'correct flash message'
  end

  ### restricted GET-'edit'/update access - for non-signed-in users ###

  def test_deny_access_to_edit
    user = signed_in_user
    sign_out
    get :edit, :id => user
    assert_redirected_to signin_path
  end

  def test_deny_access_to_update
    user = signed_in_user
    sign_out
    put :update, :id => user, :user => {}
    assert_redirected_to signin_path
    assert flash[:notice] =~ /sign\s+in/i, 'correct flash message'
  end

  ### restricted GET-'edit'/update access - for non-signed-in users ###

  def test_edit_wrong_user
    _, _, user = setup_test_user
    user[:email_addr] = 'otheruser@example.net'
    @controller.sign_in(user)
    get :edit, :id => @user
    assert_redirected_to root_path
  end

  def test_update_wrong_user
    _, _, user = setup_test_user
    user[:email_addr] = 'otheruser@example.net'
    @controller.sign_in(user)
    put :update, :id => @user, :user => {}
    assert_redirected_to root_path
  end

end
