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
    @good_attr = {
      :email_addr            => 'iexist@test.org',
      :password              => 'existence-is-futile',
      :password_confirmation => 'existence-is-futile',
    }
    @dbuser = User.find_by_email_addr(@good_attr[:email_addr])
    if @dbuser == nil
      # The user is not yet in the database.
      @dbuser = User.create!(@good_attr)
      if @dbuser == nil
        @dbuser = @user
        throw "Retrieval of user at #{@good_attr[:email_addr]} failed."
      end
else
puts "<<<<<<<<<<<<<#{@dbuser.email_addr} was in the database.>>>>>>>>>>>>>"
    end
puts "<<<<<<<<<<<<<dbuser: #{@dbuser.email_addr}.>>>>>>>>>>>>>"
puts "[setup] goodattr: #{@good_attr}"
  end

  def badbadbad_setup
    @bad_attr = {:email_addr => '', :password => ''}
    @good_attr = {
      :email_addr => 'iexist@test.org',
      :password => 'existence-is-futile'
    }
    @user = Factory(:user)
    dbuser = User.find_by_email_addr(@user.email_addr)
    if dbuser == nil
      # @user is not yet in the database.
      if @user.save
        dbuser = @user
      else
        throw "Retrieval of user at #{@user.email_addr} failed."
      end
else
    end
    @nogood_attr = {
      :email_addr => dbuser.email_addr,
      :password => dbuser.password
    }
  end

  def test_bad_values
    post :create, :session => @bad_attr
    assert_response :success, 'normal response expected'
    assert_select 'title', /sign in/i, 'expected title'
    assert flash.now[:error] != nil && flash.now[:error] =~ /invalid/i,
      "flash error msg expected"
  end

  describe "successful login" do

    def test_good_values
      post :create, :session => @good_attr
      assert_response :success, 'normal response expected'
#p "SCT self:", self
#p 'SCT controller:', @controller
p 'SCT controller class:', @controller.class
p 'SCT controller current_user:', @controller.current_user
#      assert controller.current_user == @user, 'expected current user'
      #    assert_select 'title', /sign in/i, 'expected title'
    end

    def test_good_redirect
puts "[test_good_redirect] goodattr: #{@good_attr}"
      post :create, :session => @good_attr
p 'SCT controller class:', @controller.class
p 'SCT controller current_user:', @controller.current_user
      assert_redirected_to user_path(@dbuser), "successful login redirect"
      #    assert_select 'title', /sign in/i, 'expected title'
    end

  end
end
