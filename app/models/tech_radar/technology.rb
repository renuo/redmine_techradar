# frozen_string_literal: true

module TechRadar
  class Technology < ApplicationRecord
    has_many :ratings, dependent: :destroy

    validates :name, presence: true, uniqueness: true

    scope :unrated_by, lambda { |user|
      where.not(id: Rating.where(user: user).select(:technology_id)).order(:id)
    }

    # First unrated technology with an id greater than `current` (moving forward,
    # no wrap-around). `current` may be nil (entry point), giving the first unrated.
    def self.next_unrated_after(user, current = nil)
      pool = unrated_by(user)
      return pool.first if current.nil?

      pool.where('tech_radar_technologies.id > ?', current.id).first
    end
  end
end
