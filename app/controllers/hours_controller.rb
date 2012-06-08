class HoursController < ApplicationController
  unloadable

  before_filter :get_user
  before_filter :get_dates

  def index
  end

  def next
    if @current_day
      redirect_to :action => 'index', :day => (@current_day + 1).to_s(:param_date)
    else
      redirect_to :action => 'index', :week => (@week_start + 7).to_s(:param_date)
    end
  end

  def prev
    if @current_day
      redirect_to :action => 'index', :day => (@current_day - 1).to_s(:param_date)
    else
      redirect_to :action => 'index', :week => (@week_start - 7).to_s(:param_date)
    end
  end

  private

  def get_dates
    @current_day = DateTime.strptime(params[:day], Time::DATE_FORMATS[:param_date]) rescue nil
    @week_start = params[:week].nil? ? DateTime.now.beginning_of_week : DateTime.strptime(params[:week], Time::DATE_FORMATS[:param_date]).beginning_of_week
    @week_end = params[:week].nil? ? DateTime.now.end_of_week : DateTime.strptime(params[:week], Time::DATE_FORMATS[:param_date]).end_of_week
  end

  def get_user
    render_403 unless User.current.logged?

    if params[:user_id] && params[:user_id] != User.current.id.to_s
      if User.current.admin?
        @user = User.find(params[:user_id])
      else
        render_403
      end
    else
      @user = User.current
    end
  end

end
