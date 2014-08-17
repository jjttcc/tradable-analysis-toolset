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

  # MasClient object for 'user'
  def mas_client(user)
      @mas_client = MasClientTools::mas_client(user: current_user)
  end

  public ###  Status report

  # Is 'user' the current user?
  def current_user?(user)
    user == current_user
  end

  def signed_in?
    session != nil && session[:user_id] != nil
  end

  public ###  Basic operations

  # Sign in 'user'
  pre :user_exists do |user| user != nil end
  #post :signed_in do |user| current_user == user and signed_in? end
  def sign_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  # Sign out 'user'
  def sign_out
    if current_user != nil
      MasClientTools::logout_client(current_user)
      if current_user.mas_session != nil
        current_user.mas_session.destroy
      end
      @current_user = nil
      session.delete(:user_id)
    end
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

  def authenticate
    if not signed_in?
      deny_access
    end
  end

end
