# frozen_string_literal: true

module TechRadar
  class Rating < ApplicationRecord
    self.table_name = 'tech_radar_ratings'

    belongs_to :user
    belongs_to :technology

    enum :can_level,  { unknown: 1, beginner: 2, advanced: 3, professional: 4 }
    enum :want_level, { no: 1, probably_no: 2, neutral: 3, probably_yes: 4, yes: 5 }

    validates :user_id, uniqueness: { scope: :technology_id }
  end
end
