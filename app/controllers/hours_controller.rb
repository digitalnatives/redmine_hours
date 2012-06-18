class HoursController < ApplicationController
  unloadable

  before_filter :get_user
  before_filter :get_dates
  before_filter :get_issues

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

  def save_weekly
    params['hours'].each do |day, issue_hash|
      issue_hash.each do |issue_id, activity_hash|
        activity_hash.each do |activity_id, hours|
          te = TimeEntry.find_or_create_by_user_id_and_issue_id_and_activity_id_and_spent_on(@user.id,
                                                                                        issue_id.to_i,
                                                                                        activity_id.to_i,
                                                                                        day)
          .update_attributes(:hours => hours.to_f) unless hours.blank?
        end
      end
    end
    redirect_to :action => 'index', :week => @week_start.to_s(:param_date)
  end

  private

  def get_dates
    @current_day = DateTime.strptime(params[:day], Time::DATE_FORMATS[:param_date]) rescue nil
    @week_start = params[:week].nil? ? DateTime.now.beginning_of_week : DateTime.strptime(params[:week], Time::DATE_FORMATS[:param_date]).beginning_of_week
    @week_end = params[:week].nil? ? DateTime.now.end_of_week : DateTime.strptime(params[:week], Time::DATE_FORMATS[:param_date]).end_of_week
  end

  def get_issues
    weekly_time_entries = TimeEntry.for_user(@user).spent_between(@week_start, @week_end).sort_by{|te| te.issue.project.name}.sort_by{|te| te.issue.subject }
    @week_issue_matrix = {}
    weekly_time_entries.each do |te|
      @week_issue_matrix["#{te.issue.project.name} - #{te.issue.subject} - #{te.activity.name}"] ||= {:issue_id => te.issue_id, :activity_id => te.activity_id}
      @week_issue_matrix["#{te.issue.project.name} - #{te.issue.subject} - #{te.activity.name}"][te.spent_on.to_s(:param_date)] = te.hours
    end


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
