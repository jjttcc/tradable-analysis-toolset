class PeriodTypeSpecsController < ApplicationController
  include Contracts::DSL

  before_filter :authenticate
  before_filter :ensure_correct_user, :only => [:destroy]

  NEW_PTS_TITLE = 'Create period-type specification'

  def new
    @user = current_user
    make_period_type_id_to_name_map
    @title = NEW_PTS_TITLE
  end

  def create
    period_type_spec = current_user.period_type_specs.build(
      params[:period_type_spec])
    if period_type_spec.save
      redirect_to user_path(current_user.id),
        :flash => { :success => 'New spec created.' }
    else
      @title = NEW_PTS_TITLE
      @object = period_type_spec
      make_period_type_id_to_name_map
      render 'new'
    end
  end

  def destroy
    pspec = PeriodTypeSpec.find_by_id(params[:id])
    if pspec != nil
      pspec.destroy
      redirect_to user_path(current_user.id),
        :flash => { :success => 'spec deleted.' }
    end
  end

  private

  def make_period_type_id_to_name_map
    @period_type_id_for = {}
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
