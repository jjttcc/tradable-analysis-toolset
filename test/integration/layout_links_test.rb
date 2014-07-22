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
    get '/signout'
    assert_redirected_to root_path
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

  def setup
    @good_attr, @bad_attr, @good_user = setup_test_user
  end

  def sign_in
    visit signin_path
    fill_in 'Email address', :with => @good_user.email_addr
    fill_in 'Password', :with => @good_user.password
    click_button 'Submit'
  end

  describe "while signed in" do
    test 'should have a sign-out link' do
      sign_in
      visit root_path
      page.find_link('Sign out').wont_be_nil
    end

    test 'should have a profile link' do
      sign_in
      visit root_path
      page.find_link('Profile').wont_be_nil
    end
  end

end
