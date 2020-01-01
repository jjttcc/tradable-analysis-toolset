require "test_helper"

class FriendlyForwardingTest < ActionDispatch::IntegrationTest

  def test_forward_to_edit_page_after_signin
    _, _, user = setup_test_user
    visit edit_user_path({id: user.id})
    sign_in_without_visiting(user)
    # (Expect redirect to originally requested [edit] page.)
    assert current_path == "/users/#{user.id}/edit", 'correct path [1]'
    visit signout_path
    visit signin_path
    sign_in_without_visiting(user)
    expected_path = "/users/#{user.id}"
    assert (current_path == expected_path ||
            current_path == locale_path(expected_path)), 'correct path [2]'
  end

  def test_forward_to_correct_user_edit_page_after_signin
    _, _, user = setup_test_user
    _, _, user2 = setup_test_user_with_eaddr('testemail@testthis.org')
    wrong_id = user2.id
    # Go to the edit page of a different user:
    visit edit_user_path({id: wrong_id})
    sign_in_without_visiting(user)
    visit signout_path
    visit signin_path
    sign_in_without_visiting(user)
    expected_path = "/users/#{user.id}"
    assert (current_path == expected_path ||
            current_path == locale_path(expected_path)),
              'path with id of logged-in user'
  end

end
