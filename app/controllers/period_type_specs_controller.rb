class PeriodTypeSpecsController < ApplicationController
  include Contracts::DSL

  before_filter :authenticate

  NEW_PTS_TITLE = 'Create period-type specification'

  def new
    @user = current_user
    make_period_type_id_to_name_map
=begin
    @period_type_id_for = {}
    PeriodTypeConstants::ids.each do |id|
      @period_type_id_for[PeriodTypeConstants::name_for[id]] = id
    end
=end
    @title = NEW_PTS_TITLE
  end

  def create
    period_type_spec = current_user.period_type_specs.build(
      params[:period_type_spec])
    if period_type_spec.save
      redirect_to root_path, :flash => { :success => 'New spec created.' }
    else
      @title = NEW_PTS_TITLE
      @object = period_type_spec
      make_period_type_id_to_name_map
      render 'new'
=begin
      if ! period_type_spec.valid?
        @user = current_user
        #raise period_type_spec.errors.messages.inspect
        flash[:failure => 'NOT GOOD']
          #:flash => { :errors => period_type_spec.errors.messages }
      else
raise "Sorry - save failed."
      end
      @motd = MOTD.new  #!!!!!filler!!!!!!!!!!
      render 'pages/home'
=end
    end
  end

  def destroy
    pspec = PeriodTypeSpec.find_by_id(params[:id])
    if pspec != nil
      pspec.destroy
      redirect_to root_path, :flash => { :success => 'spec deleted.' }
    else
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

end
