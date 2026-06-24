# frozen_string_literal: true

module TechRadar
  # Walks technologies in a stable, rating-independent order so that each card's
  # previous/next neighbors are deterministic and page visits stay idempotent.
  class RatingQueue
    def initialize(user)
      @user = user
    end

    # All technologies in the stable deck order
    def cards
      @cards ||= Technology.order(:id).to_a
    end

    # Entry point: first technology the user has not rated yet
    def first_unrated
      cards.find { |technology| !rated_technology_ids.include?(technology.id) }
    end

    def previous(technology)
      neighbor(technology, -1)
    end

    def following(technology)
      neighbor(technology, 1)
    end

    private

    def neighbor(technology, offset)
      index = cards.index { |card| card.id == technology.id }
      return nil if index.nil?

      position = index + offset
      position.negative? ? nil : cards[position]
    end

    def rated_technology_ids
      @rated_technology_ids ||= Rating.where(user: @user).pluck(:technology_id)
    end
  end
end
