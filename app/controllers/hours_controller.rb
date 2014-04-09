class HoursController < ApplicationController
  unloadable

  before_filter :get_user
  before_filter :get_dates
  before_filter :get_issues

  def index
    used_issues = @weekly_time_entries.map(&:issue_id)
    issues_assigned_to_me = Issue.visible.open.
      where(:assigned_to_id => ([User.current.id] + User.current.group_ids))
    issues_assigned_to_me_not_used_recently = if used_issues.present?
                                                 issues_assigned_to_me.where("#{Issue.table_name}.id NOT IN (?)", used_issues )
                                               else
                                                 issues_assigned_to_me
                                               end
    @issues_assigned_to_me_not_used_recently = issues_assigned_to_me_not_used_recently.limit(10).
      includes(:status, :project, :tracker, :priority).
      order("#{IssuePriority.table_name}.position DESC, #{Issue.table_name}.updated_on DESC")

    my_time_entries_sorted_count = TimeEntry.where("user_id = ? AND issue_id IS NOT NULL AND updated_on > ?",
                                                   User.current.id,
                                                   1.month.ago).
                                                   count(group: :issue_id).
                                                   sort { |a, b| b.last <=> a.last }
    issue_ids = my_time_entries_sorted_count.first(10).map(&:first)
    @my_most_used_issues = Issue.where("id in (?)", issue_ids)
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
        activity_hash.each do |activity_id, other_hash|
          other_hash.each do |id, hours|
            id = id.to_i > 0 ? id : nil
            attributes = if issue_id =~ /no_issue/
                           {
                             id: id,
                             user_id: @user.id,
                             project_id: issue_id.split(":").last,
                             issue_id: nil,
                             activity_id: activity_id,
                             spent_on: day
                           }
                         else
                           {
                             id: id,
                             user_id: @user.id,
                             issue_id: issue_id,
                             activity_id: activity_id,
                             spent_on: day
                           }
                         end
            hours_value = parse_hours(hours)
            TimeEntry.where(attributes).first_or_create.update_attributes(:hours => hours_value) if hours_value > 0
          end
        end
      end
    end
    redirect_to :back
  end

  def save_daily
    params['hours'].each { |te_id, hash| TimeEntry.find(te_id).update_attributes(:hours => parse_hours(hash['spent']), :comments => hash['comments']) }
    redirect_to :back
  end

  def delete_row
    TimeEntry.for_user(@user).spent_between(@week_start, @week_end).find(:all, :conditions => ["issue_id = \"#{params[:issue_id]}\" AND activity_id = \"#{params[:activity_id]}\" "]).each(&:delete)
    TimeEntry.for_user(@user).spent_between(@week_start, @week_end).find(:all, :conditions => ["project_id = \"#{params[:project_id]}\" AND issue_id IS NULL AND activity_id = \"#{params[:activity_id]}\" "]).each(&:delete)
    redirect_to :back
  end

  private

  def get_dates
    @current_day = DateTime.strptime(params[:day], Time::DATE_FORMATS[:param_date]) rescue nil
    if @current_day
      @week_start = @current_day.beginning_of_week
      @week_end = @current_day.end_of_week
    else
      @week_start = params[:week].nil? ? DateTime.now.beginning_of_week : DateTime.strptime(params[:week], Time::DATE_FORMATS[:param_date]).beginning_of_week
      @week_end = params[:week].nil? ? DateTime.now.end_of_week : DateTime.strptime(params[:week], Time::DATE_FORMATS[:param_date]).end_of_week
    end
  end

  def get_issues
    @loggable_projects = Project.all.select{ |pr| @user.allowed_to?(:log_time, pr)}

    @weekly_time_entries = TimeEntry.for_user(@user).spent_between(@week_start, @week_end)

    @week_issues = []
    @weekly_time_entries.each do |te|
      time_entry_hash = { :id => te.id,
                          :issue_id => te.issue_id,
                          :activity_id => te.activity_id,
                          :project_id => te.project.id,
                          :project_name => te.project.name,
                          :issue_text => te.issue.try(:to_s),
                          :spent_on => te.spent_on.to_s(:param_date),
                          :activity_name => te.activity.name
      }
      time_entry_hash[:issue_class] ||= te.issue.closed? ? 'issue closed' : 'issue' if te.issue
      time_entry_hash[te.spent_on.to_s(:param_date)] = {:hours => te.hours, :te_id => te.id, :comments => te.comments}
      @week_issues << time_entry_hash
    end

    @daily_totals = {}

    (@week_start..@week_end).each do |day|
      @daily_totals[day.to_s(:param_date)] = TimeEntry.for_user(@user).spent_on(day).map(&:hours).inject(:+)
    end

    @daily_issues = @week_issues.select{|time_entry_hash| time_entry_hash[@current_day.to_s(:param_date)]} if @current_day

    if @week_issues.empty?
      last_week_time_entries = TimeEntry.for_user(@user).spent_between(@week_start-7, @week_end-7).sort_by{|te| te.issue.project.name}.sort_by{|te| te.issue.subject }
      last_week_time_entries.each do |te|
        time_entry_hash = { :id => te.id,
                            :issue_id => te.issue_id,
                            :activity_id => te.activity_id,
                            :project_id => te.issue.project.id,
                            :project_name => te.issue.project.name,
                            :issue_text => te.issue.to_s,
                            :activity_name => te.activity.name
        }
        time_entry_hash[:issue_class] ||= te.issue.closed? ? 'issue closed' : 'issue'
      end
    end
    @week_issues = @week_issues.group_by { |h| [h[:issue_id], h[:activity_id]] }.map do |k, group|
      [k, group.group_by { |h| h[:spent_on] }]
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

  private

  def parse_hours(hours)
    hours.tr(",", ".").to_f
  end
end
