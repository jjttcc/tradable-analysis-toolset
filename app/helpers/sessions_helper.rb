require 'ruby_contracts'

module SessionsHelper
  include Contracts::DSL

  pre :user_exists do |user| user != nil end
  #post :signed_in do |user| current_user == user and signed_in? end
  def sign_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  def current_user
    if @current_user == nil && session != nil
      @current_user = User.find_by_id(session[:user_id])
    end
    @current_user
  end

  def current_user?(user)
    user == current_user
  end

  def signed_in?
    session != nil && session[:user_id] != nil
  end

  def signed_in_user
    unless signed_in?
      store_location
      redirect_to signin_path, notice: "Please sign in."
    end
  end

  def sign_out
    @current_user = nil
    session.delete(:user_id)
  end

  def redirect_back_or_to(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def deny_access
    store_location
    redirect_to signin_path, :notice => "Please sign in."
  end

  private

  def clear_return_to
    session.delete(:return_to)
  end

end
