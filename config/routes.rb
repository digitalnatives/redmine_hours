hours_routes = {
  '/hours'    => {:controller => 'hours', :action => 'index'},
  '/hours/n'  => {:controller => 'hours', :action => 'next'},
  '/hours/p'  => {:controller => 'hours', :action => 'prev'},
  '/hours/sw' => {:controller => 'hours', :action => 'save_weekly'},
  '/hours/sd' => {:controller => 'hours', :action => 'save_daily'},
  '/hours/del'=> {:controller => 'hours', :action => 'delete_row'},
}

if Redmine::VERSION::MAJOR == 1
  ActionController::Routing::Routes.draw do |map|
    hours_routes.each do |route_name, route_action|
      map.connect route_name, route_action
    end
  end
else
  RedmineApp::Application.routes.draw do
    hours_routes.each do |route_name, route_action|
      controller_name = route_action[:controller]
      action_name = route_action[:action]
      match route_name, to: "#{controller_name}##{action_name}"
    end
  end
end
