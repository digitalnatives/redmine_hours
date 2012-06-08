require 'redmine'

Time::DATE_FORMATS[:week] = "%Y %b %e"

Redmine::Plugin.register :redmine_hours do
  name 'Redmine Hours plugin'
  description 'Harvest like work hour management'
  version '0.0.1'

	project_module :hours do
  	permission :view_hours, :work_time => :index
	end

	menu(:top_menu, :hours, {:controller => "hours", :action => 'index'}, :caption => 'Hours', :after => :my_page, :if => Proc.new{ User.current.logged? }, :param => :user_id)

end
