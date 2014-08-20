class PeriodTypeSpecsController < ApplicationController
  include ControllerFacilities
  include Contracts::DSL

  before_filter :authenticate
  before_filter :ensure_correct_user, :only => [:edit, :destroy]

  NEW_PTS_TITLE       = 'Create period-type specification'
  EDIT_PTS_TITLE      = 'Edit period-type specification'
  EARLIEST_START_YEAR = 1950
  LATEST_END_YEAR     = DateTime.now.year + 10
  FLASH               = { :update  => 'Spec updated',
                          :create  => 'New spec created',
                          :destroy => 'Spec deleted', }

  def new
    @user = current_user
    make_view_helper_vars
    @title = NEW_PTS_TITLE
    @default_start_year = EARLIEST_START_YEAR
    @default_end_year = LATEST_END_YEAR
  end

  def create
    period_type_spec = current_user.period_type_specs.build(
      params[:period_type_spec])
    if period_type_spec.save
      redirect_to user_path(current_user.id),
        :flash => { :success => FLASH[:create] }
    else
      @title = NEW_PTS_TITLE
      @object = period_type_spec
      make_view_helper_vars
      render 'new'
    end
  end

  pre :signed_in do signed_in? end
  post :title_edit_pts do @title == EDIT_PTS_TITLE end
  post :ptype_spec do @period_type_spec != nil end
  def edit
    @period_type_spec = PeriodTypeSpec.find(params[:id])
    @title = EDIT_PTS_TITLE
    @default_start_year = EARLIEST_START_YEAR
    @default_end_year = LATEST_END_YEAR
    make_view_helper_vars
  end

  pre :signed_in do signed_in? end
  def update
    @period_type_spec = PeriodTypeSpec.find(params[:id])
    replacement_pts_params = {}; orig_pts_params = params[:period_type_spec]
    orig_pts_params.keys.each do |k|
      if k =~ /effective.*_date/
        # e.g., turn 'effective_start_date' into 'start_date':
        key = k.sub("effective_", "")
      else
        key = k
      end
      replacement_pts_params[key] = orig_pts_params[k]
    end
    if @period_type_spec.update_attributes(replacement_pts_params)
      flash[:success] = FLASH[:update]
      redirect_to user_path(current_user.id)
    else
      @title = EDIT_USER_TITLE
      render 'edit'
    end
  end

  post :spec_gone do PeriodTypeSpec.find_by_id(params[:id]) == nil end
  def destroy
    pspec = PeriodTypeSpec.find_by_id(params[:id])
    if pspec != nil
      pspec.destroy
      redirect_to user_path(current_user.id),
        :flash => { :success => FLASH[:destroy] }
    end
  end

  private

  # Create convenience variables to be used by views.
  def make_view_helper_vars
    @period_type_id_for = {}
    @categories = PeriodTypeSpec::VALID_CATEGORY.keys
    PeriodTypeConstants::ids.each do |id|
      @period_type_id_for[PeriodTypeConstants::name_for[id]] = id
    end
    @period_type_id_for
  end

  def ensure_correct_user
    pt_spec = PeriodTypeSpec.find_by_id(params[:id])
    if pt_spec.user != current_user
      redirect_to root_path
    end
  end

end
