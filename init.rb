require 'redmine'

Time::DATE_FORMATS[:week] = "%Y %b %e"
Time::DATE_FORMATS[:param_date] = "%Y-%m-%d"
Time::DATE_FORMATS[:day] = "%a %e"
Time::DATE_FORMATS[:day_full] = "%Y %b %e, %A"
Time::DATE_FORMATS[:database] = "%a, %d %b %Y"

Rails.configuration.to_prepare do
  TimeEntry.class_eval do
    user_lambda = lambda { |user| where(user_id: user) }
    spent_on_lambda = lambda { |date| where(spent_on: date.to_date) }

    if Redmine::VERSION::MAJOR == 1
      named_scope :for_user, user_lambda
      named_scope :spent_on, spent_on_lambda
    else
      scope :for_user, user_lambda
      scope :spent_on, spent_on_lambda
    end
  end

  Project.class_eval do
    def open_issues
      self.issues.reject(&:closed?)
    end
  end
end


Redmine::Plugin.register :redmine_hours do
  name 'Redmine Hours Plugin'
  author 'Digital Natives'
  description 'Redmine Hours is a plugin to fill out your weekly timelog / timesheet easier.'
  version '0.1.1'
  url 'https://github.com/digitalnatives/redmine_hours'

  permission :view_hours, :work_time => :index

  menu(:top_menu, :hours, {:controller => "hours", :action => 'index'}, :caption => 'Hours', :after => :my_page, :if => Proc.new{ User.current.logged? }, :param => :user_id)

end
