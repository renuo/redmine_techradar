# frozen_string_literal: true

module TechRadar
  class CardDeck
    def initialize(user, state)
      @user = user
      @state = state
      @state[:history] ||= []
      @state[:position] ||= 0
    end

    def current_card
      @current_card ||= load_current_card
    end

    def current_rating
      return nil unless current_card

      Rating.find_by(user: @user, technology: current_card)
    end

    def skip!
      @state[:position] = position + 1
      @current_card = nil
    end

    def back!
      @state[:position] = [position - 1, 0].max
      @current_card = nil
    end

    def record!(can_level, want_level)
      return nil unless current_card

      rating = Rating.find_or_initialize_by(user: @user, technology: current_card)
      rating.can_level = can_level
      rating.want_level = want_level
      rating.save!
      skip!
      rating
    end

    def done?
      current_card.nil?
    end

    def last_unrated?
      return false unless current_card
      return false if rated_technology_ids.include?(current_card.id)

      position + 1 >= history.length && next_unrated_technology.nil?
    end

    private

    def load_current_card
      while position < history.length
        technology = Technology.find_by(id: history[position])
        return technology if technology

        history.delete_at(position)
      end

      next_unrated = next_unrated_technology
      return nil unless next_unrated

      history.push(next_unrated.id)
      next_unrated
    end

    def history
      @state[:history]
    end

    def position
      @state[:position]
    end

    def rated_technology_ids
      Rating.where(user: @user).pluck(:technology_id)
    end

    def next_unrated_technology
      excluded_ids = (history + rated_technology_ids).uniq
      Technology.where.not(id: excluded_ids).order(:id).first
    end
  end
end
