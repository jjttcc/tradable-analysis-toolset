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
    end
  end

  def test_bad_values
    post :create, :session => @bad_attr
    assert_response :success, 'normal response expected'
    assert_select 'title', /sign in/i, 'expected title'
    assert flash.now[:error] != nil && flash.now[:error] =~ /invalid/i,
      "flash error msg expected"
  end

  describe "successful login" do

    def test_good_redirect
      post :create, :session => @good_attr
      assert_redirected_to user_path(@dbuser), "successful login redirect"
    end

  end
end
