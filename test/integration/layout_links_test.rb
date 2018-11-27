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
    assert_select 'title', /Log in/
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
    click_link 'Log in'
  end

  describe "when not logged in" do
    test 'should have a sign-in link' do
      get '/'
      assert_select 'a[href=?]', "#{signin_path}",
        { :count => 1, :text => 'Log in' }
    end
  end

  def setup
    @good_attr, @bad_attr, @good_user = setup_test_user
    @admin_user = setup_test_user_with_eaddr('admin@users.org')[2]
    @admin_user.toggle!(:admin)
    @non_admin_user = setup_test_user_with_eaddr('non_admin@users.org')[2]
  end

  describe "while signed in" do
    test 'should have a sign-out link' do
      sign_in(@good_user)
      visit root_path
      page.find_link('Log out').wont_be_nil
    end

    test 'should have a profile link' do
      sign_in(@good_user)
      visit root_path
      page.find_link('Settings').wont_be_nil
    end

    test 'should have a settings link' do
      sign_in(@good_user)
      visit root_path
      page.find_link('Account').wont_be_nil
    end

    test 'admin should have a users link' do
      user = @admin_user
      assert user.admin?, 'user is an admin'
      sign_in(user)
      visit root_path
      begin
        page.find_link('Users')
      rescue Exception => e
        assert false, 'Users link should have been found.'
      end
    end

    test 'non-admin should NOT have a users link' do
      user = @non_admin_user
      assert ! user.admin?, 'user is NOT an admin'
      sign_in(user)
      visit root_path
      begin
        page.find_link('Users')
      rescue Exception => e
        assert e.to_s =~ /unable.*find.*link/i,
          'users link should not be found'
      end
    end

  end

end
