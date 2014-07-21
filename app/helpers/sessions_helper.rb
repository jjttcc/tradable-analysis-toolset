require 'ruby_contracts'

module SessionsHelper
  include Contracts::DSL

  public

  attr_reader :current_user

  pre :user_exists do user != nil end
  post :signed_in do signed_in? end
  def sign_in(user)
    #!!!!!!!!WARNING: cookie-based sessions - to be replaced by DB-based
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    @current_user = user
    throw "! signed_in" if ! signed_in?
  end

  pre :signed_in do signed_in? end
  post :not_signed_in do ! signed_in? end
  def sign_out
    cookies.delete(:remember_token)
#!!!![when using database, delete the session here]
    @current_user = nil
  end

  def current_user
    @current_user ||= user_from_remember_token
  end

  # Is 'current_user' signed in?
  def signed_in?
    @why = ''
    result = current_user != nil
    if not result
      @why = 'current_user was nil'
    end
    result
  end

  private

  def user_from_remember_token
    User.authenticated_with_salt(*remember_token)
  end

  def remember_token
    cookies.signed[:remember_token] || [nil, nil]
  end

end
