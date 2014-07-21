require "test_helper"

class LayoutLinksTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  test "should have home page at '/'" do
    get '/'
    assert_response :success
    assert_select 'title', /Home/
  end

  test "should have about page at '/about'" do
    get '/about'
    assert_response :success
    assert_select 'title', /About/
  end

  test "should have help page at '/help'" do
    get '/help'
    assert_response :success
    assert_select 'title', /Help/
  end

  test "should have new login page at '/signup'" do
    get '/signup'
    assert_response :success
    assert_select 'title', /login/
  end

  test "should have sign-in page at '/signin'" do
    get '/signin'
    assert_response :success
    assert_select 'title', /Sign in/
  end

  test "should have sign-out page at '/signout'" do
implementation_ready=false  #!!!!!!FIXME!!!!!
    if implementation_ready
      get '/signout'
      assert_response :success
#!!!!!!!bogus, i believe:
      assert_select 'title', /Sign out/
    end
  end

  test "should have the right links on the layout" do
    visit root_path
    first(:link, 'Help').click
    click_link 'Home'
    click_link 'About'
    click_link 'Sign in'
  end

  describe "when not logged in" do
    test 'should have a sign-in link' do
      get '/'
      assert_select 'a[href=?]', "#{signin_path}",
        { :count => 1, :text => 'Sign in' }
    end
  end

  def sign_in
    @user = Factory(:user)
    visit signin_path
    fill_in 'Email address', :with => @user.email_addr
    fill_in 'Password', :with => @user.password
    click_button 'Submit'
  end

  describe "when logged in" do
    test 'should have a sign-out link' do
      sign_in
      get '/'
      assert_select 'a[href=?]', "#{signout_path}",
        { :count => 1, :text => 'Sign out' }
    end
  end

end
