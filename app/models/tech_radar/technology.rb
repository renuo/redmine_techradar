# frozen_string_literal: true

module TechRadar
  class Technology < ApplicationRecord
    self.table_name = 'tech_radar_technologies'

    has_many :ratings, dependent: :destroy

    validates :name, presence: true, uniqueness: true
  end
end
