# frozen_string_literal: true

class TechRadarRatingsController < ApplicationController
  before_action :require_login
  before_action :authorize_global
  before_action :set_technology, only: [:show, :update]

  def index
    @technology_pages, @technologies = paginate(TechRadar::Technology.order(:id))
    @ratings = TechRadar::Rating.where(user: User.current).index_by(&:technology_id)
  end

  def rate
    technology = rating_queue.first_unrated
    return render :show unless technology

    redirect_to tech_radar_rate_technology_path(technology)
  end

  def save
    technology = TechRadar::Technology.find_by(id: params[:technology_id])
    return head :not_found unless technology

    levels = submitted_levels
    return head :unprocessable_entity unless levels

    TechRadar::Rating.record_for(User.current, technology, *levels)
    redirect_to tech_radar_ratings_path(page: params[:page])
  end

  def show
    @rating = TechRadar::Rating.find_by(user: User.current, technology: @technology)
    @previous = rating_queue.previous(@technology)
    @following = rating_queue.following(@technology)
  end

  def update
    levels = submitted_levels
    return head :unprocessable_entity unless levels

    TechRadar::Rating.record_for(User.current, @technology, *levels)

    following = rating_queue.following(@technology)
    if following
      redirect_to tech_radar_rate_technology_path(following)
    else
      redirect_to tech_radar_rating_path
    end
  end

  private

  def submitted_levels
    rating_params = params[:rating]
    return unless rating_params.is_a?(ActionController::Parameters)

    can_level = rating_params[:can_level]
    want_level = rating_params[:want_level]
    return unless TechRadar::Rating.can_levels.key?(can_level) &&
                  TechRadar::Rating.want_levels.key?(want_level)

    [can_level, want_level]
  end

  def rating_queue
    @rating_queue ||= TechRadar::RatingQueue.new(User.current)
  end

  def set_technology
    @technology = TechRadar::Technology.find(params[:technology_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
