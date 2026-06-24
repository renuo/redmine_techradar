# frozen_string_literal: true

require_relative '../../test_helper'

module TechRadar
  class RatingQueueTest < ActiveSupport::TestCase
    fixtures :users

    def setup
      @user = User.find_by(login: 'jsmith')
      @t1 = Technology.create!(name: 'Ruby')
      @t2 = Technology.create!(name: 'Rails')
      @t3 = Technology.create!(name: 'Stimulus')
      @queue = RatingQueue.new(@user)
    end

    def test_cards_returns_all_technologies_in_id_order
      assert_equal [@t1, @t2, @t3], @queue.cards
    end

    def test_first_unrated_returns_first_technology_the_user_has_not_rated
      Rating.create!(user: @user, technology: @t1, can_level: :advanced, want_level: :yes)

      assert_equal @t2, @queue.first_unrated
    end

    def test_first_unrated_is_nil_when_every_technology_is_rated
      [@t1, @t2, @t3].each do |technology|
        Rating.create!(user: @user, technology: technology, can_level: :unknown, want_level: :neutral)
      end

      assert_nil @queue.first_unrated
    end

    def test_following_returns_the_next_card_in_order
      assert_equal @t2, @queue.following(@t1)
    end

    def test_following_returns_the_next_card_even_when_it_is_already_rated
      Rating.create!(user: @user, technology: @t2, can_level: :advanced, want_level: :yes)

      assert_equal @t2, @queue.following(@t1)
    end

    def test_following_is_nil_for_the_last_card
      assert_nil @queue.following(@t3)
    end

    def test_previous_returns_the_prior_card_in_order
      assert_equal @t1, @queue.previous(@t2)
    end

    def test_neighbors_are_nil_for_a_technology_outside_the_deck
      stranger = Technology.new(id: 0, name: 'Outsider')

      assert_nil @queue.previous(stranger)
      assert_nil @queue.following(stranger)
    end
  end
end
