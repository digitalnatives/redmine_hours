ActionController::Routing::Routes.draw do |map|
  map.connect '/hours', :controller => 'hours', :action => 'index'
  map.connect '/hours/n', :controller => 'hours', :action => 'next'
  map.connect '/hours/p', :controller => 'hours', :action => 'prev'
  map.connect '/hours/sw', :controller => 'hours', :action => 'save_weekly'
  map.connect '/hours/del', :controller => 'hours', :action => 'delete_row'
end