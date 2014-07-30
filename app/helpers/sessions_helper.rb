require 'ruby_contracts'

module SessionsHelper
  include Contracts::DSL

  pre :user_exists do |user| user != nil end
  #post :signed_in do |user| current_user == user and signed_in? end
  def sign_in(user)
#    cookies.permanent[:remember_token] = user.remember_token
#    self.current_user = user
    session[:user_id] = user.id
#    @current_user = user  #!!!!!!?????????????
  end

#!!!!obsolete, I think
  def current_user=(user)
raise "current_user method is obsolete"
#    @current_user = user
  end

  def current_user
    if @current_user == nil
      @current_user = User.find_by_id(session[:user_id])
    end
    @current_user
#!!!!!@current_user ||= user_from_remember_token
  end

  def current_user?(user)
    user == current_user
  end

  def signed_in?
#current_user.nil?
session != nil && session[:user_id] != nil
  end

  def signed_in_user
    unless signed_in?
      store_location
      redirect_to signin_path, notice: "Please sign in."
    end
  end

  def sign_out
#    session.delete
    @current_user = nil
session[:user_id] = nil
#raise "session[:user_id].nil?: '#{session[:user_id].nil?}'"
  end

  def old_coockie_based____sign_out
    self.current_user = nil
    cookies.delete(:remember_token)
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

#!!!!obsolete, I think
  def user_from_remember_token
    remember_token = cookies[:remember_token]
    User.find_by_remember_token(remember_token) unless remember_token.nil?
  end

  def clear_return_to
    session.delete(:return_to)
  end

end
