# frozen_string_literal: true

class TechRadarController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def index
    @users = TechRadar::Rating.users_with_ratings
    @technologies = TechRadar::Rating.technologies_with_ratings

    @user_id = filter_id(params[:user_id], @users)
    @technology_id = filter_id(params[:technology_id], @technologies)
    return head :unprocessable_entity if @user_id == :invalid || @technology_id == :invalid

    @user_id = nil if @technology_id

    @points = if @technology_id
                TechRadar::Rating.points_for_technology(@technology_id)
              elsif @user_id
                TechRadar::Rating.points_for_user(@user_id)
              else
                TechRadar::Rating.centroids_by_technology
              end
  end

  private

  def filter_id(param, scope)
    return nil if param.blank?

    id = param.to_i
    scope.exists?(id: id) ? id : :invalid
  end
end
