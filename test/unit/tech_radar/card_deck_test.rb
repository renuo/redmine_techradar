# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class CardDeckTest < ActiveSupport::TestCase
    fixtures :users

    def setup
      @user = User.find_by(login: 'jsmith')
      @t1 = Technology.create!(name: 'Ruby')
      @t2 = Technology.create!(name: 'Rails')
      @t3 = Technology.create!(name: 'Stimulus')
      @state = {}
    end

    def test_current_card_returns_first_unrated_technology_in_id_order
      deck = CardDeck.new(@user, @state)

      assert_equal @t1, deck.current_card
      assert_not deck.done?
    end

    def test_current_card_returns_nil_when_no_technologies_exist
      Technology.delete_all
      deck = CardDeck.new(@user, @state)

      assert_nil deck.current_card
      assert_predicate deck, :done?
    end

    def test_current_card_returns_nil_when_all_technologies_rated
      [@t1, @t2, @t3].each do |t|
        Rating.create!(user: @user, technology: t, can_level: :unknown, want_level: :neutral)
      end
      deck = CardDeck.new(@user, @state)

      assert_nil deck.current_card
      assert_predicate deck, :done?
    end

    def test_advance_walks_through_unrated_technologies
      deck = CardDeck.new(@user, @state)
      visited = []
      4.times do
        visited << deck.current_card
        deck.advance!
      end

      assert_equal [@t1, @t2, @t3, nil], visited
    end

    def test_retreat_clamps_at_zero
      deck = CardDeck.new(@user, @state)
      deck.retreat!

      assert_equal @t1, deck.current_card
    end

    def test_retreat_returns_to_previously_visited_card
      deck = CardDeck.new(@user, @state)
      deck.current_card
      deck.advance!
      deck.current_card
      deck.retreat!

      assert_equal @t1, deck.current_card
    end

    def test_record_creates_rating_for_current_card
      deck = CardDeck.new(@user, @state)
      deck.current_card

      deck.record!(:advanced, :yes)

      rating = Rating.find_by(user: @user, technology: @t1)

      assert_equal 'advanced', rating.can_level
      assert_equal 'yes', rating.want_level
    end

    def test_record_twice_on_same_card_keeps_one_row_with_second_values
      deck = CardDeck.new(@user, @state)
      deck.current_card

      deck.record!(:beginner, :no)
      deck.record!(:professional, :yes)

      ratings = Rating.where(user: @user, technology: @t1)

      assert_equal 1, ratings.count
      assert_equal 'professional', ratings.first.can_level
      assert_equal 'yes', ratings.first.want_level
    end

    def test_record_returns_nil_when_deck_is_done
      Technology.delete_all
      deck = CardDeck.new(@user, @state)

      assert_nil deck.record!(:advanced, :yes)
    end

    def test_current_card_removes_stale_history_entry_and_advances
      deck = CardDeck.new(@user, @state)
      deck.current_card
      deck.advance!
      deck.current_card
      stale_id = @t2.id
      @t2.destroy!

      reloaded = CardDeck.new(@user, @state)

      assert_equal @t3, reloaded.current_card
      assert_not_includes @state[:history], stale_id
    end

    def test_current_rating_returns_existing_rating_after_back_navigation
      deck = CardDeck.new(@user, @state)
      deck.current_card
      deck.record!(:advanced, :yes)
      deck.advance!
      deck.current_card
      deck.retreat!

      assert_equal @t1, deck.current_card
      assert_equal 'advanced', deck.current_rating.can_level
      assert_equal 'yes', deck.current_rating.want_level
    end

    def test_current_rating_returns_nil_when_no_card
      Technology.delete_all
      deck = CardDeck.new(@user, @state)

      assert_nil deck.current_rating
    end
  end
end
