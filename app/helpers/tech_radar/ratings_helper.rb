# frozen_string_literal: true

module TechRadar
  module RatingsHelper
    def can_level_options
      TechRadar::Rating.can_levels.keys.map { |k| [t("tech_radar.rate.can.#{k}"), k] }
    end

    def want_level_options
      TechRadar::Rating.want_levels.keys.map { |k| [t("tech_radar.rate.want.#{k}"), k] }
    end

    # The day in the viewer's time zone, not UTC
    def last_edited_on(rating)
      format_date(User.current.time_to_date(rating.updated_at))
    end
  end
end
