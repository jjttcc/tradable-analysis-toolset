require 'ruby_contracts'

class UsersController < ApplicationController
  include Contracts::DSL
  before_filter :authenticate,        :only => [:edit, :update, :show]
  before_filter :ensure_correct_user, :only => [:edit, :update, :show]

  def new
    @user = User.new
    @title = "Create login"
  end

  pre :signed_in do signed_in? end
  post :title_email do @title == @user.email_addr end
  def show
    @user = User.find(params[:id])
    @title = @user.email_addr
  end

  post :user_exists do @user != nil end
  post :curusr_if_signed_in do implies signed_in?, current_user == @user end
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

  pre :signed_in do signed_in? end
  post :title_editu do @title == "Edit user" end
  def edit
    @user = User.find(params[:id])
    @title = "Edit user"
  end

  pre :signed_in do signed_in? end
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

  private

  def authenticate
    if not signed_in?
      deny_access
    end
  end

  def ensure_correct_user
    user = User.find(params[:id])
    if user != current_user
      redirect_to root_path
    end
  end

end
