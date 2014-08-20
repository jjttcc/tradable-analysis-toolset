require 'ruby_contracts'

class SessionsController < ApplicationController
  include ControllerFacilities
  include Contracts::DSL

  public

  SIGN_IN_TITLE = 'Sign in'

  def new
    @title = SIGN_IN_TITLE
  end

  pre :params_session_exists do params != nil && params[:session] != nil end
  def create
    user = User.authenticated(params[:session][:email_addr],
                              params[:session][:password])
    if user != nil
      sign_in user
      redirect_back_or_to user
    else
      flash.now[:error] = "Invalid email/password combination"
      @title = SIGN_IN_TITLE
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end

end
