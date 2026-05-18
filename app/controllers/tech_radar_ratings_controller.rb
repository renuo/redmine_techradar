# frozen_string_literal: true

class TechRadarRatingsController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def show
    @technology = deck.current_card
    @rating = deck.current_rating
    @last_unrated = deck.last_unrated?
  end

  def update
    can_level = params.dig(:rating, :can_level)
    want_level = params.dig(:rating, :want_level)

    unless TechRadar::Rating.can_levels.key?(can_level) &&
           TechRadar::Rating.want_levels.key?(want_level)
      return head :unprocessable_entity
    end

    deck.record!(can_level, want_level)
    deck.advance!
    redirect_to tech_radar_rating_path
  end

  def skip
    deck.advance! unless deck.last_unrated?
    redirect_to tech_radar_rating_path
  end

  def back
    deck.retreat!
    redirect_to tech_radar_rating_path
  end

  private

  def deck
    session[:tech_radar_rate] ||= {}
    @deck ||= TechRadar::CardDeck.new(User.current, session[:tech_radar_rate])
  end
end
