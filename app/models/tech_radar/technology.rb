# frozen_string_literal: true

module TechRadar
  class Technology < ApplicationRecord
    has_many :ratings, dependent: :destroy

    validates :name, presence: true, uniqueness: true
  end
end
