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

      it "new user - home" do
        visit signup_path
        fill_in 'Email address',    :with => "email2@mailers.org"
        fill_in 'Password',         :with => "mypersonalpassword"
        fill_in 'Confirm password', :with => "mypersonalpassword"
        click_button 'Submit'
        assert page.has_css?('div.flash.success'), 'success flash'
        assert page.has_text?('Welcome'), 'has flash msg'
        visit root_path
        assert page.has_text?('signal types'), 'has expected contents'
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
          user = signed_in_user
          click_link 'Log out'   # prove signed in
          click_link 'Log in'    # prove signed out
        end
      end
    end

  end

end
