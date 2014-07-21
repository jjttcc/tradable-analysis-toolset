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

end
