class UsersController < ApplicationController
  def new
    @title = "Create login"
  end

  def show
    @user = User.find(params[:id])
    @title = @user.email_addr
  end
end
