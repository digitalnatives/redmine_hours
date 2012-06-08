class HoursController < ApplicationController
  unloadable

  before_filter :get_user

  def index
  end

  private

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
