class HoursViewHookListener < Redmine::Hook::ViewListener
  render_on :view_layouts_base_html_head, :partial => 'hooks/rh_include_scripts'
end

