require 'ruby_contracts'

class SessionsController < ApplicationController
  include Contracts::DSL

  SIGN_IN_TITLE = 'Sign in'

  def new
    @title = SIGN_IN_TITLE
  end

  pre :params_session_exists do params != nil && params[:session] != nil end
  def create
#!!!!Should it be: self.current_user = ...???!!!
    user = User.authenticated(params[:session][:email_addr],
                              params[:session][:password])
#raise "signed_in: #{signed_in?}"
    if user != nil
      sign_in(user)
#!!!!!!!!!!!!!!!!!!!!session[:user_id] = user.id
      redirect_back_or_to user
    else
#raise "signed_in: #{signed_in?}"
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
