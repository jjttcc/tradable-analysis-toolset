require "test_helper"

module TestControllerHelper

  def signed_in_user(u = nil)
    if u != nil
      user = u
    else
    _, _, user = setup_test_user
    end
    @controller.sign_in(user)
    user
  end

  def sign_out
    @controller.sign_out
  end

end
