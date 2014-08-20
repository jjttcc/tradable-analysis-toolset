class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper

  def index
    @motd = MOTD.new
  end

  public ###  Access

  # MasClient object for 'user'
  def mas_client(user)
      @mas_client = MasClientTools::mas_client(user: current_user)
  end

  protected

  def store_location
    session[:return_to] = request.fullpath
  end

  def deny_access
    store_location
    redirect_to signin_path, :notice => "Please sign in."
  end

  def redirect_back_or_to(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  def clear_return_to
    session.delete(:return_to)
  end

  def authenticate
    if not signed_in?
      deny_access
    end
  end

end
