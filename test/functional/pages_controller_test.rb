require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test "should get home" do
    get :home
    assert_response :success
    assert_select 'title', /(TradableAnalysisToolset|TAT)\s*\|\s*Home/
    assert response.body.length > 16, "body exists"
  end

  test "should get about" do
    get :about
    assert_response :success
    assert_select 'title',
      Regexp.new("(TradableAnalysisToolset|TAT)\s*\|\s*About")
    assert response.body.length > 16, "body exists"
  end

end
