# frozen_string_literal: true

class TechRadarController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def index
    @users = TechRadar::Rating.users_with_ratings
    @user_id = params[:user_id].presence&.to_i
    @user_id = nil unless @user_id && @users.exists?(id: @user_id)
    @points = @user_id ? TechRadar::Rating.points_for_user(@user_id) : TechRadar::Rating.centroids_by_technology
  end
end
