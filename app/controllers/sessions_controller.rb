class SessionsController < ApplicationController
  SIGN_IN_TITLE = 'Sign in'

  def new
    @title = SIGN_IN_TITLE
  end

  def create
p 'PARAMS:', params
p 'PARAMS[:session]:', params[:session]
    user = User.authenticated(params[:session][:email],
                              params[:session][:password])
    if user != nil
      ####
    else
      flash.now[:error] = "Invalid email/password combination"
      @title = SIGN_IN_TITLE
      render 'new'
    end
  end

  def destroy
  end

end
