# frozen_string_literal: true

module TechRadar
  class RatingsController < ApplicationController
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

      redirect_to tech_radar_rating_path(technology)
    end

    def show
      @rating = TechRadar::Rating.find_by(user: User.current, technology: @technology)
      @previous = rating_queue.previous(@technology)
      @following = rating_queue.following(@technology)
    end

    def update
      levels = submitted_levels
      return head :unprocessable_entity unless levels

      TechRadar::Rating.rate!(User.current, @technology, *levels)
      redirect_to after_update_path
    end

    private

    # The overview table and the card flow share this single update action; they
    # only differ in where to go afterwards. The table sends `from=list` to
    # return to the same page, the card flow advances to the next technology.
    def after_update_path
      return tech_radar_ratings_path(page: params[:page]) if params[:from] == 'list'

      following = rating_queue.following(@technology)
      following ? tech_radar_rating_path(following) : rate_tech_radar_ratings_path
    end

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
end
