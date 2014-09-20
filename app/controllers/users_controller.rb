
class UsersController < ApplicationController
  include ControllerFacilities
  include Contracts::DSL

  before_filter :authenticate,        :only => [:edit, :update, :show,
                                                :index, :destroy]
  before_filter :ensure_correct_user, :only => [:edit, :update, :show]
  before_filter :ensure_admin,        :only => [:destroy, :index]

  NEW_USER_TITLE = 'Create login'
  EDIT_USER_TITLE = 'Edit user'
  INDEX_USER_TITLE = 'User list'

  pre :signed_in do signed_in? end
  post :title do @title == INDEX_USER_TITLE end
  post :users do @users != nil end
  def index
    @users = User.paginate(:page => params[:page])
    @title = INDEX_USER_TITLE
  end

  def new
    @user = User.new
    @title = NEW_USER_TITLE
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
      @title = NEW_USER_TITLE
      render 'new'
    end
  end

  pre :signed_in do signed_in? end
  post :title_editusr do @title == EDIT_USER_TITLE end
  def edit
    @user = User.find(params[:id])
    @title = EDIT_USER_TITLE
  end

  pre :signed_in do signed_in? end
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:success] = "Settings updated."
      redirect_to @user
    else
      @title = EDIT_USER_TITLE
      render 'edit'
    end
  end

  pre :user_is_admin do signed_in? and current_user.admin? end
  pre :target_exists do User.find_by_id(params[:id]) != nil end
  post :user_removed do tgt = User.find_by_id(params[:id])
                        tgt == current_user || tgt == nil end
  def destroy
    u = User.find(params[:id])
    if u != current_user
      u.destroy
      flash[:success] = "#{u.email_addr} deleted"
    else
      flash[:failure] = "Failed: admin cannot delete itself."
    end
    redirect_to users_path
  end

  private

  def ensure_correct_user
    user = User.find_by_id(params[:id])
    if user != current_user
      redirect_to root_path
    end
  end

  def ensure_admin
    if ! current_user.admin?
      redirect_to root_path
    end
  end

end
