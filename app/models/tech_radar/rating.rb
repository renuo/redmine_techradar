# frozen_string_literal: true

module TechRadar
  class Rating < ApplicationRecord
    self.table_name = 'tech_radar_ratings'

    belongs_to :user
    belongs_to :technology

    enum :can_level,  { unknown: 0, beginner: 1, advanced: 2, professional: 3 }
    enum :want_level, { no: 0, probably_no: 1, neutral: 2, probably_yes: 3, yes: 4 }

    validates :user_id, uniqueness: { scope: :technology_id }
  end
end
