require 'ruby_contracts'

module SessionsHelper
  include Contracts::DSL

  public ###  Access

  # The current, logged-in user
  def current_user
    if @current_user == nil && session != nil
      @current_user = User.find_by_id(session[:user_id])
    end
    @current_user
  end

  public ###  Status report

  # Is 'user' the current user?
  def current_user?(user)
    user == current_user
  end

  def signed_in?
    session != nil && session[:user_id] != nil
  end

end
