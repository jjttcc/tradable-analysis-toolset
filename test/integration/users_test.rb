require "test_helper"

class UsersTest < ActionDispatch::IntegrationTest

  include Capybara::DSL
  ### signup ###

  describe "signup" do

    describe "failure" do
      it "should NOT make a new user" do
        oldcount = User.count
        visit signup_path
        fill_in 'Email address',    :with => ""
        fill_in 'Password',         :with => ""
        fill_in 'Confirm password', :with => ""
        click_button 'Submit'
        #         assert current_path == what_path_should_i_be?
        assert page.has_css?('div#error_explanation'), 'has errors'
        assert User.count == oldcount
      end
    end

    describe "success" do
      it "should make a new user" do
        oldcount = User.count
        visit signup_path
        fill_in 'Email address',    :with => "email@mailers.org"
        fill_in 'Password',         :with => "mypersonalpassword"
        fill_in 'Confirm password', :with => "mypersonalpassword"
        click_button 'Submit'
        assert User.count == oldcount + 1, "one more user"
        assert page.has_css?('div.flash.success'), 'success flash'
        assert page.has_text?('Welcome'), 'has flash msg'
      end
    end

    describe "signin" do

      describe "failure" do
        it "should not sign a user in" do
          visit signin_path
          fill_in "Email address", :with => ""
          fill_in "Password",      :with => ""
          click_button 'Submit'
          assert page.has_css?('div.flash.error'), 'Invalid'
        end
      end

      describe "success" do
        it "should sign a user in and out" do
          a, b, user = setup_test_user
          visit signin_path
          fill_in "Email address", :with => user.email_addr
          fill_in "Password",      :with => user.password
          click_button 'Submit'
          click_link 'Sign out'   # prove signed in
          click_link 'Sign in'    # prove signed out
        end
      end
    end

  end

end
