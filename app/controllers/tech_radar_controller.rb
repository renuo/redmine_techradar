# frozen_string_literal: true

class TechRadarController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def index
    @users = TechRadar::Rating.users_with_ratings
    @technologies = TechRadar::Rating.technologies_with_ratings

    @user_id = params[:user_id].presence&.to_i
    @user_id = nil unless @user_id && @users.exists?(id: @user_id)

    @technology_id = params[:technology_id].presence&.to_i
    @technology_id = nil unless @technology_id && @technologies.exists?(id: @technology_id)

    @user_id = nil if @technology_id

    @points = if @technology_id
                TechRadar::Rating.points_for_technology(@technology_id)
              elsif @user_id
                TechRadar::Rating.points_for_user(@user_id)
              else
                TechRadar::Rating.centroids_by_technology
              end
  end
end
