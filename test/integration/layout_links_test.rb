require "test_helper"

class LayoutLinksTest < ActionDispatch::IntegrationTest
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
end
