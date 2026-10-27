# frozen_string_literal: true

module TechRadar
  # Ratings listed in the table on the evaluation page. It follows the chart's
  # filters and lists ratings best first.
  class RatingTable
    def initialize(user_id: nil, technology_id: nil)
      @user_id = user_id
      @technology_id = technology_id
    end

    def count
      @count ||= scope.count
    end

    def ratings(offset: 0, limit: nil)
      scope.offset(offset).limit(limit).to_a
    end

    private

    def scope
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
  end
end
