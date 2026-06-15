# frozen_string_literal: true

class TechRadarRatingsController < ApplicationController
  before_action :require_login
  before_action :authorize_global
  # Browsers cache the card and show a stale one on "back", so we force a fresh request.
  after_action :prevent_caching, only: [:index, :show]

  def index
    technology = TechRadar::Technology.next_unrated_after(User.current)
    return render :show unless technology

    redirect_to tech_radar_rate_technology_path(technology)
  end

  def show
    @technology = TechRadar::Technology.find_by(id: params[:technology_id])
    return head :not_found unless @technology

    @rating = TechRadar::Rating.find_by(user: User.current, technology: @technology)
    @next_unrated = TechRadar::Technology.next_unrated_after(User.current, @technology)
  end

  def update
    technology = TechRadar::Technology.find_by(id: params[:technology_id])
    return head :not_found unless technology

    can_level = params.dig(:rating, :can_level)
    want_level = params.dig(:rating, :want_level)

    unless TechRadar::Rating.can_levels.key?(can_level) &&
           TechRadar::Rating.want_levels.key?(want_level)
      return head :unprocessable_entity
    end

    TechRadar::Rating.find_or_initialize_by(user: User.current, technology: technology)
                     .update!(can_level: can_level, want_level: want_level)

    next_unrated = TechRadar::Technology.next_unrated_after(User.current, technology)
    if next_unrated
      redirect_to tech_radar_rate_technology_path(next_unrated)
    else
      redirect_to tech_radar_rating_path
    end
  end

  private

  def prevent_caching
    response.headers['Cache-Control'] = 'no-store'
  end
end
