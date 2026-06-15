# frozen_string_literal: true

module TechRadar
  class Technology < ApplicationRecord
    has_many :ratings, dependent: :destroy

    validates :name, presence: true, uniqueness: true

    scope :unrated_by, lambda { |user|
      where.not(id: Rating.where(user: user).select(:technology_id)).order(:id)
    }

    # First unrated technology with an id greater than `current`
    def self.next_unrated_after(user, current = nil)
      pool = unrated_by(user)
      return pool.first if current.nil?

      pool.where(arel_table[:id].gt(current.id)).first
    end
  end
end
