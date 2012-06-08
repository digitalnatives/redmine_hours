class HoursController < ApplicationController
  unloadable

  before_filter :get_user
  before_filter :get_dates

  def index
  end

  def next_week
    redirect_to :action => 'index', :week => @week_start + 7
  end

  def prev_week
    redirect_to :action => 'index', :week => @week_start - 7
  end

  private

  def get_dates
    @current_day = DateTime.now
    @week_start = params[:week].nil? ? DateTime.now.beginning_of_week : DateTime.strptime(params[:week], '%Y-%m-%dT%H:%M:%S%z').beginning_of_week
    @week_end = params[:week].nil? ? DateTime.now.end_of_week : DateTime.strptime(params[:week], '%Y-%m-%dT%H:%M:%S%z').end_of_week
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
