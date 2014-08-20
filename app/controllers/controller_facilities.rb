require 'ruby_contracts'

module ControllerFacilities
  include Contracts::DSL

  public

  # Sign in 'user'
  pre :user_exists do |user| user != nil end
  #post :signed_in do |user| current_user == user and signed_in? end
  def sign_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  # Sign out 'user', delete user.mas_session.
  def sign_out
    if current_user != nil
      MasClientTools::logout_client(current_user)
      @current_user = nil
      session.delete(:user_id)
    end
  end

end
