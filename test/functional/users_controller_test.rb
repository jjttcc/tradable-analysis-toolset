require "test_helper"

class UsersControllerTest < ActionController::TestCase
  def test_new
    get :new
    assert_response :success
  end

  def test_correct_title
    get :new
    assert_select 'title', /Create.*login/
  end

  def test_correct_body
    get :new
    assert_select 'body', /Create.*login/
  end

end
