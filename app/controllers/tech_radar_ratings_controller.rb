# frozen_string_literal: true

class TechRadarRatingsController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def index
    @technology_pages, @technologies = paginate(TechRadar::Technology.order(:id))
    @ratings = TechRadar::Rating.where(user: User.current).index_by(&:technology_id)
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
    @technology = deck.current_card
    @rating = deck.current_rating
    @last_unrated = deck.last_unrated?
  end

  def update
    levels = submitted_levels
    return head :unprocessable_entity unless levels

    deck.record!(*levels)
    redirect_to tech_radar_rating_path
  end

  def skip
    deck.skip! unless deck.last_unrated?
    redirect_to tech_radar_rating_path
  end

  def back
    deck.back!
    redirect_to tech_radar_rating_path
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

  def deck
    session[:tech_radar_rate] ||= {}
    @deck ||= TechRadar::CardDeck.new(User.current, session[:tech_radar_rate])
  end
end
