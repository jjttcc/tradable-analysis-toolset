class UsersController < ApplicationController
  def new
    @user = User.new
    @title = "Create login"
  end

  def show
    @user = User.find(params[:id])
    @title = @user.email_addr
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      appname = Rails.configuration.application_name
      flash[:success] = "Welcome to #{appname}"
      redirect_to @user
    else
      @title = 'Create login'
      render 'new'
    end
  end

end
