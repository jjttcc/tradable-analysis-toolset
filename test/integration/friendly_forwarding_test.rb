require "test_helper"

class FriendlyForwardingTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  def test_forward_to_edit_page_after_signin
    _, _, user = setup_test_user
    visit edit_user_path(user)
    sign_in_without_visiting(user)
    # (Expect redirect to originally requested [edit] page.)
    assert current_path == "/users/#{user.id}/edit", 'correct path'
    visit signout_path
    visit signin_path
    sign_in_without_visiting(user)
    assert current_path == "/users/#{user.id}", 'correct path'
  end

  def test_forward_to_correct_user_edit_page_after_signin
    _, _, user = setup_test_user
    _, _, user2 = setup_test_user_with_eaddr('testemail@testthis.org')
    wrong_id = user2.id
    # Go to the edit page of a different user:
    visit edit_user_path(wrong_id)
    sign_in_without_visiting(user)
    visit signout_path
    visit signin_path
    sign_in_without_visiting(user)
    assert current_path == "/users/#{user.id}", 'path with id of logged-in user'
  end

end
