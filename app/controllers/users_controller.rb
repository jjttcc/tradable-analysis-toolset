class UsersController < ApplicationController
  def new
    @user = User.new
    @title = "Create login"
  end

  def show
    @user = User.find(params[:id])
    @title = @user.email_addr
  end

  def create(*args)
    p args
  end

end
