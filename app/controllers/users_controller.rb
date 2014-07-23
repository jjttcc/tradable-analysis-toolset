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
      flash[:success] = "Welcome to #{appname}."
      sign_in(@user)
      redirect_to @user
    else
      @title = 'Create login'
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
    @title = "Edit user"
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated."
      redirect_to @user
    else
      @title = "Edit user"
      render 'edit'
    end
  end

end
