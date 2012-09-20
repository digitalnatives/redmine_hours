RedmineApp::Application.routes.draw do
  match '/hours', :to => 'hours#index'
  match '/hours/n', :to => 'hours#next'
  match '/hours/p', :to => 'hours#prev'
  match '/hours/sw', :to => 'hours#save_weekly'
  match '/hours/sd', :to => 'hours#save_daily'
  match '/hours/del', :to => 'hours#delete_row'
end