ActionController::Routing::Routes.draw do |map|
  map.connect '/my/hours', :controller => 'hours', :action => 'index'
end