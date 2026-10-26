# frozen_string_literal: true

module TechRadar
  # Rows of the ratings table on the evaluation page. It follows the chart's
  # filters and lists ratings best first. Unless filtered by person, raters who
  # haven't rated yet follow at the end, without a rating.
  class RatingTable
    Row = Struct.new(:user, :technology, :rating)

    def initialize(user_id: nil, technology_id: nil)
      @user_id = user_id
      @technology_id = technology_id
    end

    def rows
      rated = ratings.map { |rating| Row.new(rating.user, rating.technology, rating) }
      return rated if @user_id

      technology = Technology.find(@technology_id) if @technology_id
      rated + missing_raters.map { |user| Row.new(user, technology, nil) }
    end

    private

    def ratings
      scope = Rating.joins(:user, :technology).preload(:user, :technology)
      best_first = { can_level: :desc, want_level: :desc }

      if @user_id
        scope.where(user_id: @user_id).order(best_first).order('tech_radar_technologies.name')
      elsif @technology_id
        scope.where(technology_id: @technology_id).order(best_first).order(*User.fields_for_order_statement)
      else
        scope.order('tech_radar_technologies.name').order(best_first).order(*User.fields_for_order_statement)
      end
    end

    def missing_raters
      rated = @technology_id ? Rating.where(technology_id: @technology_id) : Rating.all
      Rating.raters.where.not(id: rated.select(:user_id)).sorted
    end
  end
end
