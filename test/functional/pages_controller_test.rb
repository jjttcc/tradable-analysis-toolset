require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test "should get home" do
    get :home
    assert_response :success
    assert_select 'title', "TradableAnalysisToolset | Home"
    assert response.body.length > 16, "body exists"
  end

  test "should get about" do
    get :about
    assert_response :success
    assert_select 'title', "TradableAnalysisToolset | About"
    assert response.body.length > 16, "body exists"
  end

end
