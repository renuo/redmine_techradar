# frozen_string_literal: true

module TechRadar
  class Rating < ApplicationRecord
    belongs_to :user
    belongs_to :technology

    enum :can_level,  { unknown: 1, beginner: 2, advanced: 3, professional: 4 }
    enum :want_level, { no: 1, probably_no: 2, neutral: 3, probably_yes: 4, yes: 5 }

    validates :user_id, uniqueness: { scope: :technology_id }

    def self.centroids_by_technology
      joins(:technology)
        .group('tech_radar_technologies.id', 'tech_radar_technologies.name')
        .pluck(
          'tech_radar_technologies.id',
          'tech_radar_technologies.name',
          Arel.sql('AVG(can_level)'),
          Arel.sql('AVG(want_level)')
        )
        .map { |id, name, can, want| { id: id, name: name, can: can.to_f, want: want.to_f } }
    end
  end
end
