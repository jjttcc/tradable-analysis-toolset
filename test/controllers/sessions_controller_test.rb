require "test_helper"

class SessionsControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_response :success
  end

  def test_correct_title
    get :new
    assert_select 'title', /sign\s+in/i, 'sign-in title'
  end

end
