# frozen_string_literal: true

module TechRadar
  class Rating < ApplicationRecord
    belongs_to :user
    belongs_to :technology

    enum :can_level,  { unknown: 1, beginner: 2, advanced: 3, professional: 4 }
    enum :want_level, { no: 1, probably_no: 2, neutral: 3, probably_yes: 4, yes: 5 }

    # Chart points are centred so the origin sits at the middle of each scale.
    CAN_CENTER  = (can_levels.values.min + can_levels.values.max) / 2.0
    WANT_CENTER = (want_levels.values.min + want_levels.values.max) / 2.0

    validates :user_id, uniqueness: { scope: :technology_id }

    def self.rate!(user, technology, can_level, want_level)
      rating = find_or_initialize_by(user: user, technology: technology)
      rating.update!(can_level: can_level, want_level: want_level)
      rating
    end

    def self.centroids_by_technology
      joins(:technology)
        .group('tech_radar_technologies.name')
        .pluck(
          'tech_radar_technologies.name',
          Arel.sql('AVG(can_level)'),
          Arel.sql('AVG(want_level)')
        )
        .map { |name, can, want| centred_point(name, can, want) }
    end

    def self.points_for_user(user_id)
      joins(:technology)
        .where(user_id: user_id)
        .pluck(
          'tech_radar_technologies.name',
          Arel.sql('can_level AS can_raw'),
          Arel.sql('want_level AS want_raw')
        )
        .map { |name, can, want| centred_point(name, can, want) }
    end

    def self.points_for_technology(technology_id)
      joins(:user)
        .where(technology_id: technology_id)
        .pluck(
          'users.login',
          Arel.sql('can_level AS can_raw'),
          Arel.sql('want_level AS want_raw')
        )
        .map { |login, can, want| centred_point(login, can, want) }
    end

    def self.centred_point(name, can, want)
      { name: name, can: can.to_f - CAN_CENTER, want: want.to_f - WANT_CENTER }
    end
    private_class_method :centred_point

    def self.users_with_ratings
      User.where(id: select(:user_id).distinct).order(:login)
    end

    def self.technologies_with_ratings
      TechRadar::Technology.where(id: select(:technology_id).distinct).order(:name)
    end
  end
end
