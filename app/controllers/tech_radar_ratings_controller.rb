# frozen_string_literal: true

class TechRadarRatingsController < ApplicationController
  before_action :require_login
  before_action :authorize_global
  before_action :set_technology, only: [:show, :update]

  def index
    technology = rating_queue.first_unrated
    return render :show unless technology

    redirect_to tech_radar_rate_technology_path(technology)
  end

  def show
    @rating = TechRadar::Rating.find_by(user: User.current, technology: @technology)
    @previous = rating_queue.previous(@technology)
    @following = rating_queue.following(@technology)
  end

  def update
    can_level = params.dig(:rating, :can_level)
    want_level = params.dig(:rating, :want_level)

    unless TechRadar::Rating.can_levels.key?(can_level) &&
           TechRadar::Rating.want_levels.key?(want_level)
      return head :unprocessable_entity
    end

    TechRadar::Rating.find_or_initialize_by(user: User.current, technology: @technology)
                     .update!(can_level: can_level, want_level: want_level)

    following = rating_queue.following(@technology)
    if following
      redirect_to tech_radar_rate_technology_path(following)
    else
      redirect_to tech_radar_rating_path
    end
  end

  private

  def rating_queue
    @rating_queue ||= TechRadar::RatingQueue.new(User.current)
  end

  def set_technology
    @technology = TechRadar::Technology.find(params[:technology_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
