module SessionsHelper
  public

  def sign_in(user)
    #!!!!!!!!WARNING: cookie-based sessions - to be replaced by DB-based
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    current_user = user
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= user_from_remember_token
  end

  # Is 'current_user' signed in?
  def signed_in?
    @current_user != nil
  end

  private

  def user_from_remember_token
    User.authenticated_with_salt(*remember_token)
  end

  def remember_token
    cookies.signed[:remember_token] || [nil, nil]
  end

end
