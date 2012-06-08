ActionController::Routing::Routes.draw do |map|
  map.connect '/hours', :controller => 'hours', :action => 'index'
  map.connect '/hours/n', :controller => 'hours', :action => 'next'
  map.connect '/hours/p', :controller => 'hours', :action => 'prev'
end