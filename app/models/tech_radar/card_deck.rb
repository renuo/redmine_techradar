# frozen_string_literal: true

module TechRadar
  class CardDeck
    HISTORY_KEY = :history
    POSITION_KEY = :position

    def initialize(user, state)
      @user = user
      @state = state
      @state[HISTORY_KEY] ||= []
      @state[POSITION_KEY] ||= 0
    end

    def current_card
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

    def current_rating
      technology = current_card
      return nil unless technology

      Rating.find_by(user: @user, technology: technology)
    end

    def advance!
      @state[POSITION_KEY] = position + 1
    end

    def retreat!
      @state[POSITION_KEY] = [position - 1, 0].max
    end

    def record!(can_level, want_level)
      technology = current_card
      return nil unless technology

      rating = Rating.find_or_initialize_by(user: @user, technology: technology)
      rating.can_level = can_level
      rating.want_level = want_level
      rating.save!
      rating
    end

    def done?
      current_card.nil?
    end

    private

    def history
      @state[HISTORY_KEY]
    end

    def position
      @state[POSITION_KEY]
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
